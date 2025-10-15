pub mod backend;
pub mod cli;
pub mod launcher;

/// Audio device types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DeviceType {
    Sink,   // Output device
    Source, // Input device
}

impl std::fmt::Display for DeviceType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DeviceType::Sink => write!(f, "sink"),
            DeviceType::Source => write!(f, "source"),
        }
    }
}

/// Represents an audio device
#[derive(Debug, Clone)]
pub struct AudioDevice {
    pub id: u32,
    pub name: String,
    pub description: String,
    pub is_default: bool,
    pub device_type: DeviceType,
}

impl AudioDevice {
    /// Format device for display in launcher
    pub fn format_for_display(&self) -> String {
        // Emoji for device type
        let device_emoji = match self.device_type {
            DeviceType::Sink => "🔊",   // Output devices
            DeviceType::Source => "🎤", // Input devices
        };

        // Indicator for current default
        let status = if self.is_default {
            "✓" // Checkmark for current default
        } else {
            " " // Space for alignment
        };

        let hint = self.get_device_hint();
        let hint_str = if !hint.is_empty() {
            format!(" {}", hint)
        } else {
            String::new()
        };

        format!("{} {} {}{} (ID: {})", status, device_emoji, self.description, hint_str, self.id)
    }

    /// Get a hint about the device type from its name
    fn get_device_hint(&self) -> String {
        let name_lower = self.description.to_lowercase();

        // Add contextual emojis based on device name
        if name_lower.contains("hdmi") || name_lower.contains("displayport") {
            "📺".to_string() // Monitor/TV
        } else if name_lower.contains("usb") || name_lower.contains("arctis") {
            "🎧".to_string() // Headset/USB audio
        } else if name_lower.contains("speaker") {
            "🔈".to_string() // Built-in speakers
        } else if name_lower.contains("headphone") {
            "🎧".to_string() // Headphones
        } else if name_lower.contains("digital microphone") || name_lower.contains("mic") {
            "🎙️".to_string() // Microphone
        } else {
            "".to_string() // No extra hint
        }
    }

    /// Parse device from launcher selection
    pub fn parse_id_from_selection(selection: &str) -> Option<u32> {
        // Format: "✓ 🔊 Device Name 🎧 (ID: 123)"
        // Extract ID from "(ID: 123)" at the end
        selection
            .split("(ID: ")
            .nth(1)?
            .split(')')
            .next()?
            .parse()
            .ok()
    }
}
