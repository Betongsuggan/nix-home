use audiomenu::{cli::Cli, AudioDevice};
use clap::Parser;

fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<()> {
    let cli = Cli::parse();

    // Create backend
    let backend_type: audiomenu::backend::Backend = cli.backend.into();
    let backend = backend_type.create();

    // Convert CLI types to internal types
    let device_type: audiomenu::DeviceType = cli.device_type.into();
    let launcher: audiomenu::launcher::Launcher = cli.launcher.into();

    // List available devices
    let devices = backend.list_devices(device_type)?;

    if devices.is_empty() {
        eprintln!("No {} devices found", device_type);
        return Ok(());
    }

    // Format devices for display
    let options: Vec<String> = devices
        .iter()
        .map(|d| d.format_for_display())
        .collect();

    // Show launcher menu
    let prompt = format!("Select {} device:", device_type);
    let selection = launcher.show_menu(&options, Some(&prompt))?;

    // Parse selected device ID
    let device_id = AudioDevice::parse_id_from_selection(&selection)
        .ok_or_else(|| anyhow::anyhow!("Failed to parse device ID from selection"))?;

    // Set as default and optionally move streams
    backend.set_default_and_move_streams(device_id, device_type, cli.move_streams)?;

    if cli.move_streams {
        println!("Successfully set default {} to device ID: {} (and moved active streams)", device_type, device_id);
    } else {
        println!("Successfully set default {} to device ID: {}", device_type, device_id);
    }

    Ok(())
}
