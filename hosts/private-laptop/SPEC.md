# Private Laptop

Personal Intel-based convertible laptop (i7-1165G7, 16 GB) for daily use, light development, light gaming and game streaming from the private desktop. Runs Hyprland with a single `betongsuggan` user, set up like bits but deliberately lighter (the root disk is small).

## Key Features

- Hyprland (the window-manager default: scrolling layout mimicking niri, see `modules/window-manager/SPEC.md`) with accelerometer screen rotation in tablet mode (`my.controls.utils.autoScreenRotation`). External displays through the Hyprland lid script and the launcher's monitor menu (Mod+M); no kanshi (its profiles are bits' monitors)
- Alacritty terminal (module default), Bash with Starship
- Vicinae launcher with wifi and bluetooth extensions
- Firefox (`my.firefox`); no Chromium, no Slack (`my.communication` off)
- Development: toolchains come from each repository's dev shell (`use flake` in `.envrc`, cached by nix-direnv, `my.direnv`), not from the system: `my.development` keeps gh and the AI tools (`infra.enable = false`, no language flags); the editor keeps only Nix. No Docker
- Moonlight client for streaming from the desktop
- Light gaming: Steam via `my.games` (no store launchers/Wine prefix managers, MangoHud only for games launched with `mangohud`)
- Intel power tuning: `cpuVendor = "intel"` (TLP energy-performance preferences) and thermald
- `my.profiles.laptop` (implies workstation): touchpad, backlight, TLP, battery notifications, bluetooth, printing, and the lean boot/shutdown/rebuild defaults (loader timeout 0, 10 s stop timeouts, option manuals off)
- File manager (Thunar)
- Stylix theming with Banana cursor
- Secret management for Anthropic and Tavily API keys
- IIO sensor support for screen auto-rotation (`hardware.sensor.iio`)
- Intel graphics with firmware updates via fwupd (on demand)
- Firewall with port 8080 open for development

## Tailnet

Onboarded member (`my.home-network.mode = "onboarded"`), sops secrets from `nix-vault/secrets/private-laptop.yaml`
(tailnet preauth key and the user's `id_rsa`, placed at `~/.ssh/id_rsa` by the sops module).

## Notes

- Hardware: Intel CPU with KVM support (`kvm-intel` module) and Intel WiFi (`iwlwifi`)
- Kernel: the default LTS series (`pkgs.linuxPackages`)
- NTFS filesystem support for accessing Windows drives
- Timezone: Europe/Stockholm
- Colemak keyboard layout
- Nothing autostarts; MangoHud only for games launched with `mangohud`; game store/prefix tools are off (Steam and Moonlight stay)
- Switched from niri to Hyprland and slimmed down on 2026-11-25 (card 158): dropped Docker, the global Python/Node/Go toolchains, Slack, Chromium, kanshi and Ghostty. Closure: 20.4 GiB before, 12.8 GiB after (`nix path-info -S` on the toplevel; the old one was also on an older nixpkgs). Largest remaining paths: linux-firmware 0.8 GiB, wine 0.8 GiB and Discord 0.6 GiB (both from `my.games`), two LLVM libs (Mesa) 1.1 GiB, Firefox 0.4 GiB
- Steam comes from `programs.steam` (the games module's NixOS half, since `my.games.enable` is set), with nix-gaming's SteamOS sysctls; no Remote Play ports are opened on this host
