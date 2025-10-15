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
}

impl AudioBackend for PipeWireBackend {
    fn list_devices(&self, _device_type: DeviceType) -> Result<Vec<AudioDevice>> {
        let _output = self.run_wpctl(&["status"])?;

        // TODO: Parse wpctl status output
        // For now, return empty list as a stub
        Ok(Vec::new())
    }

    fn set_default(&self, device_id: u32) -> Result<()> {
        self.run_wpctl(&["set-default", &device_id.to_string()])
            .context("Failed to set default device")?;
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
}
