# Private Desktop

Personal gaming and development desktop with AMD Ryzen CPU and RDNA4 GPU. Runs two user sessions: `betongsuggan` for general desktop use and development, and `gamer` as a dedicated auto-login gaming session with HDR, game streaming, and console-mode support.

## Key Features

- Two-user setup: `betongsuggan` (development/daily use) and `gamer` (dedicated gaming)
- Gamer user auto-logs in on TTY1 and launches Hyprland automatically
- Hyprland compositor on both users with HDR-enabled ultrawide (3440x1440@240) and 4K HDMI monitors
- Sunshine game streaming server with virtual SUNSHINE monitor for headless streaming, scoped to the `gamer` session (`game-streaming.server.user = "gamer"`) so betongsuggan's session doesn't spawn a competing instance
- Console-mode with Gamescope session for Steam Deck-like experience
- Steam Big Picture auto-start on gamer session with SteamOS 3 features
- Logitech G13 gaming keypad with declarative key remapping via input-remapper (auto-applies on connect)
- PS5 DualSense controller support with rumble and MangoHud toggle
- GameMode with GPU optimizations and CPU renicing for gaming performance
- MangoHud overlay with detailed mode and vkBasalt post-processing
- Proton-GE for enhanced Windows game compatibility
- Vulkan environment uses Mesa/RADV defaults (only HDR + present-mode vars); RDNA2-era tuning vars (`RADV_PERFTEST`, `VKD3D_CONFIG=dxr*`, etc.) were removed after they caused severe UE5 performance regressions — see `modules/graphics/SPEC.md`
- RetroArch with 10 libretro cores (SNES, NES, GB/GBC/GBA, N64, NDS, PSX, Mega Drive, Dreamcast, Saturn, Arcade), saves/states declaratively inside the synced `~/emulation/saves/retroarch/{saves,states}` tree, a baked udev autoconfig for the Sunshine virtual pad, and a Select+Start quit chord (Select+Guide opens the RetroArch menu)
- Standalone emulators: PCSX2 (PS2), Dolphin (GameCube/Wii), PPSSPP (PSP); PSX is covered by the beetle-psx-hw core (Duckstation left nixpkgs 26.05)
- Per-ROM Steam tiles (gamer user, `games.emulators.steamShortcuts`): every ROM on the controller shares — SNES/NES/GB/GBC/GBA/N64/PSX/Mega Drive/Master System plus Switch — becomes a Steam Big Picture tile (streamable over Moonlight), written directly into `shortcuts.vdf` by `emulation-apply-shortcuts`. Tile artwork is fetched from SteamGridDB using an API key from the vault's shared `common.yaml` (sops → `/run/secrets/steamgriddb-api-key`, owner `gamer`; the sops entry is skipped while `common.yaml` doesn't exist in nix-vault yet). See `modules/games/SPEC.md`.
- Nintendo Switch (gamer user) via Ryubing (Ryujinx fork, from unstable). Keys/firmware are uploaded to the controller `bios/switch` Samba share and copied into Ryujinx's data dir; Switch is one `steamShortcuts` system entry (folder layout, `.xci`). See `modules/games/SPEC.md`.
- BoilR for store-launcher (Heroic/Lutris) Steam library integration; Steam ROM Manager is installed but unused (headless CLI hangs — the direct writer replaces it)
- Emulation mounts: controller's `emulation-roms` + `emulation-bios` shares auto-mount for both `betongsuggan` and `gamer` at `~/emulation/{roms,bios}`
- Emulation client (gamer user): Syncthing save sync to controller (RetroArch + Switch saves under `~/emulation/saves`) and the `mount-emulation-roms` helper, both targeting controller's tailnet FQDN (controller is tailnet-only; its LAN IP does not serve Samba/Syncthing). gamer@desktop's Syncthing device ID is registered in `lib/default.nix`, which is what lets controller accept the peer.
- Zen kernel optimized for desktop/gaming with ryzen-smu monitoring
- ZRAM swap (zstd, 50% memory) for memory efficiency
- CPU governor set to performance mode with undervolting enabled
- CPU core-performance-boost re-asserted at boot (tmpfiles) and after every resume (`powerManagement.resumeCommands`) — amd-pstate loses the boost state across suspend, capping cores at base clock, and this host auto-suspends every 30 idle minutes
- Development environment on betongsuggan user with Docker support
- Vicinae launcher with wifi, bluetooth, and monitor extensions on both users
- Firefox, communication apps, and LocalSend on both users
- Alacritty terminal with Bash shell and Starship prompt
- Bluetooth with wake support for DualSense controller
- Secure boot via Lanzaboote
- FreeSync enabled on all displays via kernel parameter
- Firewall with ports for Steam streaming and LocalSend
- Restic backup target: receives snapshots from controller into `/var/lib/restic-repos/controller/repo` via chrooted SFTP user `restic-controller` (key sourced from `lib/default.nix`). See `modules/restic-target/SPEC.md`.
- AI lab: Ollama (ROCm), Open WebUI, ComfyUI (custom `rocm/pytorch:latest`-based container), and Speaches (STT + TTS) per `modules/ai-server/SPEC.md`. Wake-on-LAN enabled so the host can sleep; controller fronts the services over HTTPS at `chat.rydback.net` / `llm.rydback.net` / `images.rydback.net` / `voice.rydback.net` (tailnet-only).
- Auto-suspend after 30 min of session-idle via `services.logind.settings.Login.IdleAction = "suspend"`. Local input, Sunshine streaming and SSH sessions all keep it awake via the normal logind idle-hint path; the rare gap is a long-running AI generation interrupted mid-stream — recovered by a client retry through controller's wake-proxy.
- SSH into `betongsuggan` over `tailscale0` is authorized for the user's own keys on `controller`, and for `birgerrydback@bits` (cross-user access from the bits host).

## Notes

- Hardware: AMD Ryzen CPU with RDNA4 GPU, using `amd_pstate=active` and full `amdgpu` feature mask
- Kernel: Zen kernel with `mitigations=off` and `preempt=full` for maximum gaming performance
- Headless-streaming bootstrap on the otherwise-unused DP-1 connector via two kernel params: `video=DP-1:1920x1080@60D` (force enumerate as connected) + `drm.edid_firmware=DP-1:edid/1920x1080.bin` (load a synthetic EDID so amdgpu doesn't NULL-deref in `dc_resource_is_dsc_encoding_supported`). The EDID binary is provisioned by `hardware.firmware = [ pkgs.edid-generator ]`, which installs `/lib/firmware/edid/1920x1080.bin` — without this, forcing the connector on with no EDID crashes amdgpu and hangs boot with CPU/GPU spinning. This gives Hyprland a guaranteed DRM output to come up on, so the `exec-once` → `graphical-session.target` → sunshine chain fires even with the real KVM/monitors off. Targeting DP-1 (unused; real monitors are on DP-2 + HDMI-A-1) means normal EDID negotiation for the actual displays is untouched.
- Remote streaming (Moonlight over the tailnet from outside the LAN): tailscaled listens on its NixOS-default fixed port UDP 41641. The home connection is double-NATed (ISP box → ASUS router, both hard NAT: `MappingVariesByDestIP: true`), so clients behind CGNAT (phone hotspots) can't hole-punch and fall back to the controller's DERP relay — TCP, too slow for the video stream. For direct paths, forward UDP 41641 through *both* NAT layers to this host (or bridge/DMZ the ISP box so the ASUS UPnP mapping is actually reachable). Moonlight's "metered connection" warning on the client is informational only.
- NTFS filesystem support enabled for accessing Windows drives
- Custom udev rules for NVMe scheduler and USB autosuspend on KVM switch and Realtek ethernet adapter
- Unstable Mesa overlay applied for latest GPU driver support on gamer user
- Timezone: Europe/Stockholm
- Colemak keyboard layout
