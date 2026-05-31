# Island Stationary

Personal gaming and development desktop with AMD Ryzen CPU and NVIDIA RTX 2070 GPU. Mirrors the private-desktop setup with two user sessions: `betongsuggan` for general desktop use and development, and `gamer` as a dedicated auto-login gaming session.

## Key Features

- Two-user setup: `betongsuggan` (development/daily use) and `gamer` (dedicated gaming)
- Gamer user auto-logs in on TTY1 and launches Hyprland automatically
- Hyprland compositor on both users with auto-detected monitors
- NVIDIA RTX 2070 GPU with proprietary drivers
- Console-mode with Gamescope session for Steam Deck-like experience
- Steam Big Picture auto-start on gamer session with SteamOS 3 features
- PS5 DualSense controller support with rumble and MangoHud toggle
- GameMode with CPU renicing for gaming performance
- MangoHud overlay with detailed mode and vkBasalt post-processing
- Proton-GE for enhanced Windows game compatibility
- NVIDIA-optimized environment variables (shader caching, NVAPI)
- Zen kernel optimized for desktop/gaming
- ZRAM swap (zstd, 50% memory) for memory efficiency
- CPU governor set to performance mode
- Development environment on betongsuggan user with Docker support
- Vicinae launcher with wifi, bluetooth, and monitor extensions on both users
- Chromium, communication apps, and LocalSend on both users
- Alacritty terminal with Bash shell and Starship prompt
- Bluetooth with wake support for DualSense controller
- Secure boot via Lanzaboote
- Firewall with ports for LocalSend
- Restic backup target: receives snapshots from controller into `/var/lib/restic-repos/controller/repo` via chrooted SFTP user `restic-controller` (key sourced from `lib/default.nix`). Off-site copy in the interim backup topology — requires island to be onboarded to the tailnet for controller to reach it. See `modules/restic-target/SPEC.md`.

## Differences from private-desktop

- NVIDIA RTX 2070 GPU instead of AMD RDNA4 (no AMD GPU env vars, no undervolting, no mesa unstable overlay)
- No game streaming server (Sunshine)
- No emulation server (Syncthing/WireGuard)
- Auto-detect monitors instead of hardcoded resolution/refresh rates

## Notes

- Hardware: AMD Ryzen CPU with NVIDIA RTX 2070 GPU
- Kernel: Zen kernel with `mitigations=off` and `preempt=full` for maximum gaming performance
- NTFS filesystem support enabled for accessing Windows drives
- Timezone: Europe/Stockholm
- Colemak keyboard layout
