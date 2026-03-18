# Bits

Work laptop for Birger Rydback at Bits. This is an AMD-based laptop running NixOS with the Niri Wayland compositor, configured for software development and daily office use.

## Key Features

- Niri tiling Wayland compositor with Vicinae launcher (wifi, bluetooth, monitor extensions)
- Development tooling with direnv, git, and SSH agent
- Firefox browser with Slack and other communication apps
- Alacritty terminal with Bash shell and Starship prompt
- Disk encryption enabled for security
- Fingerprint reader authentication
- Touchpad and backlight support
- Battery monitoring and power management
- Docker for containerized development
- Bluetooth and printer support
- LocalSend for local file sharing (with CLI)
- Colemak keyboard layout
- Stylix theming with Banana cursor
- Secret management for Tavily and LocalStack API keys
- Firewall with ports open for LocalSend (53317) and dev server (8080)

## Notes

- Hardware: AMD CPU with `amd_pstate=active` frequency scaling and microcode updates
- Kernel: Linux 6.12 with laptop-mode power optimizations (`vm.laptop_mode=5`)
- Boot: systemd-boot with Lanzaboote secure boot support
- Firmware updates via fwupd (deferred to on-demand start)
- Timezone: Europe/Stockholm
