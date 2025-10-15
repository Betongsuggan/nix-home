use crate::backend::AudioBackend;
use crate::{AudioDevice, DeviceType};
use anyhow::{Context, Result};
use std::process::Command;

/// PipeWire backend using wpctl
pub struct PipeWireBackend;

impl PipeWireBackend {
    pub fn new() -> Self {
        Self
    }

    /// Run wpctl command and get output
    fn run_wpctl(&self, args: &[&str]) -> Result<String> {
        let output = Command::new("wpctl")
            .args(args)
            .output()
            .context("Failed to execute wpctl. Is PipeWire installed?")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("wpctl failed: {}", stderr);
        }

        Ok(String::from_utf8(output.stdout)?)
    }

    /// Parse wpctl status output to extract devices
    fn parse_devices(&self, output: &str, device_type: DeviceType) -> Result<Vec<AudioDevice>> {
        let section_name = match device_type {
            DeviceType::Sink => "Sinks:",
            DeviceType::Source => "Sources:",
        };

        let mut devices = Vec::new();
        let mut in_audio_section = false;
        let mut in_target_section = false;

        for line in output.lines() {
            // Check if we're entering the Audio section
            if line.trim() == "Audio" {
                in_audio_section = true;
                continue;
            }

            // Exit Audio section when we hit Video or Settings
            if in_audio_section && (line.trim() == "Video" || line.trim() == "Settings") {
                break;
            }

            // Check if we're entering the target section (Sinks or Sources)
            if in_audio_section && line.contains(section_name) {
                in_target_section = true;
                continue;
            }

            // Exit target section when we hit another subsection
            if in_target_section && line.contains("├─") && !line.contains(section_name) {
                in_target_section = false;
                continue;
            }

            // Parse device lines
            if in_target_section && in_audio_section {
                if let Some(device) = self.parse_device_line(line, device_type) {
                    devices.push(device);
                }
            }
        }

        Ok(devices)
    }

    /// Parse a single device line from wpctl status
    /// Format: " │  *   58. Family 17h/19h/1ah HD Audio Controller Speaker [vol: 0.54]"
    /// Or:     " │      73. Radeon High Definition Audio Controller [...] [vol: 0.40]"
    /// Get all active sink-input or source-output stream IDs
    fn get_active_streams(&self, device_type: DeviceType) -> Result<Vec<u32>> {
        let output = self.run_wpctl(&["status"])?;
        let mut stream_ids = Vec::new();
        let mut in_streams_section = false;
        let stream_type_marker = match device_type {
            DeviceType::Sink => ">", // Sink inputs show ">"
            DeviceType::Source => "<", // Source outputs show "<"
        };

        for line in output.lines() {
            // Enter Streams section
            if line.contains("└─ Streams:") {
                in_streams_section = true;
                continue;
            }

            // Exit streams section
            if in_streams_section && (line.starts_with("Video") || line.starts_with("Settings")) {
                break;
            }

            // Parse stream lines - format: "        123. output_FL       > Device:port"
            if in_streams_section && line.contains(stream_type_marker) {
                // Extract stream ID from lines like "        123. output_FL       > ..."
                let trimmed = line.trim();
                if let Some(dot_pos) = trimmed.find('.') {
                    if let Ok(id) = trimmed[..dot_pos].trim().parse::<u32>() {
                        stream_ids.push(id);
                    }
                }
            }
        }

        Ok(stream_ids)
    }

    /// Move a stream to a device
    fn move_stream(&self, stream_id: u32, device_id: u32) -> Result<()> {
        self.run_wpctl(&["move", &stream_id.to_string(), &device_id.to_string()])
            .context(format!("Failed to move stream {} to device {}", stream_id, device_id))?;
        Ok(())
    }

    fn parse_device_line(&self, line: &str, device_type: DeviceType) -> Option<AudioDevice> {
        // Check if line contains a device entry
        if !line.contains("│") || !line.contains(".") {
            return None;
        }

        // Check for default marker (*)
        let is_default = line.contains("*");

        // Remove tree characters and trim
        let line = line
            .replace("│", "")
            .replace("├─", "")
            .replace("└─", "")
            .replace("*", "")
            .trim()
            .to_string();

        // Parse: "58. Family 17h/19h/1ah HD Audio Controller Speaker [vol: 0.54]"
        let parts: Vec<&str> = line.splitn(2, '.').collect();
        if parts.len() != 2 {
            return None;
        }

        // Extract ID
        let id = parts[0].trim().parse::<u32>().ok()?;

        // Extract name (remove volume info)
        let name_part = parts[1].trim();
        let description = if let Some(vol_pos) = name_part.rfind("[vol:") {
            name_part[..vol_pos].trim()
        } else {
            name_part
        }
        .to_string();

        Some(AudioDevice {
            id,
            name: description.clone(),
            description,
            is_default,
            device_type,
        })
    }
}

impl AudioBackend for PipeWireBackend {
    fn list_devices(&self, device_type: DeviceType) -> Result<Vec<AudioDevice>> {
        let output = self.run_wpctl(&["status"])?;
        self.parse_devices(&output, device_type)
    }

    fn set_default(&self, device_id: u32) -> Result<()> {
        self.run_wpctl(&["set-default", &device_id.to_string()])
            .context("Failed to set default device")?;
        Ok(())
    }

    fn set_default_and_move_streams(&self, device_id: u32, device_type: DeviceType, move_streams: bool) -> Result<()> {
        // Set the default device
        self.set_default(device_id)?;

        // Move existing streams if requested
        if move_streams {
            let stream_ids = self.get_active_streams(device_type)?;
            for stream_id in stream_ids {
                // Ignore errors when moving streams (some streams might not be movable)
                let _ = self.move_stream(stream_id, device_id);
            }
        }

        Ok(())
    }

    fn name(&self) -> &str {
        "pipewire"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_backend_creation() {
        let backend = PipeWireBackend::new();
        assert_eq!(backend.name(), "pipewire");
    }

    #[test]
    fn test_parse_sink_devices() {
        let backend = PipeWireBackend::new();
        let sample_output = r#"Audio
 ├─ Devices:
 │      44. Radeon High Definition Audio Controller [Rembrandt/Strix] [alsa]
 │      45. Family 17h/19h/1ah HD Audio Controller [alsa]
 │
 ├─ Sinks:
 │  *   58. Family 17h/19h/1ah HD Audio Controller Speaker [vol: 0.54]
 │      73. Radeon High Definition Audio Controller [Rembrandt/Strix] HDMI / DisplayPort 4 Output [vol: 0.40]
 │     112. Radeon High Definition Audio Controller [Rembrandt/Strix] HDMI / DisplayPort 1 Output [vol: 1.00]
 │
 ├─ Sources:
 │      59. Family 17h/19h/1ah HD Audio Controller Headphones Stereo Microphone [vol: 1.00]
 │  *   82. USB Audio Analog Stereo             [vol: 0.69]

Video
 ├─ Devices:
        "#;

        let devices = backend
            .parse_devices(sample_output, DeviceType::Sink)
            .unwrap();

        assert_eq!(devices.len(), 3);

        // Check first device (default)
        assert_eq!(devices[0].id, 58);
        assert_eq!(devices[0].description, "Family 17h/19h/1ah HD Audio Controller Speaker");
        assert!(devices[0].is_default);

        // Check second device
        assert_eq!(devices[1].id, 73);
        assert!(!devices[1].is_default);

        // Check third device
        assert_eq!(devices[2].id, 112);
        assert!(!devices[2].is_default);
    }

    #[test]
    fn test_parse_source_devices() {
        let backend = PipeWireBackend::new();
        let sample_output = r#"Audio
 ├─ Sinks:
 │  *   58. Family 17h/19h/1ah HD Audio Controller Speaker [vol: 0.54]
 │
 ├─ Sources:
 │      59. Family 17h/19h/1ah HD Audio Controller Headphones Stereo Microphone [vol: 1.00]
 │      60. Family 17h/19h/1ah HD Audio Controller Digital Microphone [vol: 0.96]
 │  *   82. USB Audio Analog Stereo             [vol: 0.69]

Video
        "#;

        let devices = backend
            .parse_devices(sample_output, DeviceType::Source)
            .unwrap();

        assert_eq!(devices.len(), 3);

        // Check default source
        assert_eq!(devices[2].id, 82);
        assert_eq!(devices[2].description, "USB Audio Analog Stereo");
        assert!(devices[2].is_default);

        // Check non-default
        assert!(!devices[0].is_default);
        assert!(!devices[1].is_default);
    }

    #[test]
    fn test_parse_device_line() {
        let backend = PipeWireBackend::new();

        // Test with default marker
        let line = " │  *   58. Family 17h/19h/1ah HD Audio Controller Speaker [vol: 0.54]";
        let device = backend.parse_device_line(line, DeviceType::Sink).unwrap();
        assert_eq!(device.id, 58);
        assert_eq!(device.description, "Family 17h/19h/1ah HD Audio Controller Speaker");
        assert!(device.is_default);

        // Test without default marker
        let line = " │      73. Radeon High Definition Audio Controller [Rembrandt/Strix] HDMI / DisplayPort 4 Output [vol: 0.40]";
        let device = backend.parse_device_line(line, DeviceType::Sink).unwrap();
        assert_eq!(device.id, 73);
        assert!(!device.is_default);

        // Test invalid line
        let line = " │  ├─ Devices:";
        assert!(backend.parse_device_line(line, DeviceType::Sink).is_none());
    }
}
