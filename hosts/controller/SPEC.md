# Controller

Minimal Intel NUC host intended as a controller/server. The long-term goal is to run headless without a desktop environment.

## Key Features

- Niri tiling Wayland compositor with Vicinae launcher (wifi, bluetooth, monitor extensions)
- Alacritty terminal with Bash shell and Starship prompt
- Intel integrated graphics
- Audio via PipeWire
- NetworkManager with iwd backend
- OpenSSH server (firewall port open)
- Minimal SSH git server (git-shell, single bare repo)
- Colemak keyboard layout
- Stylix theming with Banana cursor
- Single user: `betongsuggan`

## Notes

- Hardware: Intel NUC (CPU with integrated graphics)
- Kernel: Latest stable Linux kernel
- Boot: systemd-boot
- Timezone: Europe/Stockholm
- Locale: en_GB.UTF-8 with Swedish regional settings
- State version: 25.11
