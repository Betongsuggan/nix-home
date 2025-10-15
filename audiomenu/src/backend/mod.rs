pub mod pipewire;

use crate::{AudioDevice, DeviceType};
use anyhow::Result;

/// Trait for audio backend implementations
pub trait AudioBackend {
    /// List all devices of a given type
    fn list_devices(&self, device_type: DeviceType) -> Result<Vec<AudioDevice>>;

    /// Set the default device
    fn set_default(&self, device_id: u32) -> Result<()>;

    /// Set the default device and optionally move existing streams
    fn set_default_and_move_streams(&self, device_id: u32, device_type: DeviceType, move_streams: bool) -> Result<()>;

    /// Get the name of this backend
    fn name(&self) -> &str;
}

/// Backend selector
#[derive(Debug, Clone, Copy)]
pub enum Backend {
    PipeWire,
    PulseAudio, // For future implementation
}

impl Backend {
    /// Create a backend instance
    pub fn create(self) -> Box<dyn AudioBackend> {
        match self {
            Backend::PipeWire => Box::new(pipewire::PipeWireBackend::new()),
            Backend::PulseAudio => unimplemented!("PulseAudio backend not yet implemented"),
        }
    }
}

impl std::str::FromStr for Backend {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> Result<Self> {
        match s.to_lowercase().as_str() {
            "pipewire" => Ok(Backend::PipeWire),
            "pulseaudio" => Ok(Backend::PulseAudio),
            _ => Err(anyhow::anyhow!("Unknown backend: {}", s)),
        }
    }
}

impl std::fmt::Display for Backend {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Backend::PipeWire => write!(f, "pipewire"),
            Backend::PulseAudio => write!(f, "pulseaudio"),
        }
    }
}
