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
        let prefix = if self.is_default { "[*]" } else { "   " };
        format!("{} {} (ID: {})", prefix, self.description, self.id)
    }

    /// Parse device from launcher selection
    pub fn parse_id_from_selection(selection: &str) -> Option<u32> {
        // Extract ID from format: "[*]  Device Name (ID: 123)"
        selection
            .split("(ID: ")
            .nth(1)?
            .split(')')
            .next()?
            .parse()
            .ok()
    }
}
