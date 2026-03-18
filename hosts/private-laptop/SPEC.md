# Private Laptop

Personal Intel-based laptop for daily use, development, light gaming, and game streaming from the private desktop. Runs the Niri Wayland compositor with a single `betongsuggan` user.

## Key Features

- Niri tiling Wayland compositor with auto-screen-rotation support
- Kanshi for automatic display profile switching (multi-monitor)
- Ghostty terminal with vim-style keybindings and split navigation
- Vicinae launcher with wifi and bluetooth extensions
- Development tooling with Docker, git, and direnv
- Firefox browser and communication apps
- Game streaming client for streaming from private-desktop
- Light gaming support via games module
- Battery monitoring and power management
- Bluetooth, touchpad, and printer support
- Bash shell with Starship prompt
- File manager (Thunar) with system integration
- Stylix theming with Banana cursor
- Secret management for Anthropic and Tavily API keys
- IIO sensor support for screen auto-rotation
- Intel graphics with firmware updates via fwupd
- Secure boot via Lanzaboote
- Firewall with port 8080 open for development

## Notes

- Hardware: Intel CPU with KVM support (`kvm-intel` module) and Intel WiFi (`iwlwifi`)
- Kernel: Latest stable Linux kernel
- NTFS filesystem support for accessing Windows drives
- Timezone: Europe/Stockholm
- Colemak keyboard layout
