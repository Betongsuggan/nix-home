# Private Desktop

Personal gaming and development desktop with AMD Ryzen CPU and RDNA4 GPU. Runs two user sessions: `betongsuggan` for general desktop use and development, and `gamer` as a dedicated auto-login gaming session with HDR, game streaming, and console-mode support.

## Key Features

- Two-user setup: `betongsuggan` (development/daily use) and `gamer` (dedicated gaming)
- Gamer user auto-logs in on TTY1 and launches Hyprland automatically
- Hyprland compositor on both users with HDR-enabled ultrawide (3440x1440@240) and 4K HDMI monitors
- Sunshine game streaming server with virtual SUNSHINE monitor for headless streaming
- Console-mode with Gamescope session for Steam Deck-like experience
- Steam Big Picture auto-start on gamer session with SteamOS 3 features
- Logitech G13 gaming keypad with declarative key remapping via input-remapper (auto-applies on connect)
- PS5 DualSense controller support with rumble and MangoHud toggle
- GameMode with GPU optimizations and CPU renicing for gaming performance
- MangoHud overlay with detailed mode and vkBasalt post-processing
- Proton-GE for enhanced Windows game compatibility
- RDNA4-optimized Vulkan environment variables (RADV, ray tracing, HDR)
- RetroArch with 10 libretro cores (SNES, NES, GB/GBC/GBA, N64, NDS, PSX, Mega Drive, Dreamcast, Saturn, Arcade)
- Standalone emulators: PCSX2 (PS2), Dolphin (GameCube/Wii), PPSSPP (PSP), Duckstation (PSX)
- BoilR and Steam ROM Manager for unified Steam library integration (all games in one console UI)
- Emulation client (gamer user): Syncthing save sync and `mount-emulation-roms` helper targeting controller at `192.168.50.5`
- Zen kernel optimized for desktop/gaming with ryzen-smu monitoring
- ZRAM swap (zstd, 50% memory) for memory efficiency
- CPU governor set to performance mode with undervolting enabled
- Development environment on betongsuggan user with Docker support
- Vicinae launcher with wifi, bluetooth, and monitor extensions on both users
- Firefox, communication apps, and LocalSend on both users
- Alacritty terminal with Bash shell and Starship prompt
- Bluetooth with wake support for DualSense controller
- Secure boot via Lanzaboote
- FreeSync enabled on all displays via kernel parameter
- Firewall with ports for Steam streaming and LocalSend
- Restic backup target: receives snapshots from controller into `/var/lib/restic-repos/controller/repo` via chrooted SFTP user `restic-controller` (key sourced from `lib/default.nix`). See `modules/restic-target/SPEC.md`.

## Notes

- Hardware: AMD Ryzen CPU with RDNA4 GPU, using `amd_pstate=active` and full `amdgpu` feature mask
- Kernel: Zen kernel with `mitigations=off` and `preempt=full` for maximum gaming performance
- NTFS filesystem support enabled for accessing Windows drives
- Custom udev rules for NVMe scheduler and USB autosuspend on KVM switch and Realtek ethernet adapter
- Unstable Mesa overlay applied for latest GPU driver support on gamer user
- Timezone: Europe/Stockholm
- Colemak keyboard layout
