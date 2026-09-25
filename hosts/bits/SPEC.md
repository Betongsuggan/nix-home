# Bits

Work laptop for Birger Rydback at Bits. This is an AMD-based laptop running NixOS with the Hyprland Wayland compositor (scrolling layout mimicking niri), configured for software development and daily office use.

## Key Features

- Hyprland compositor using the built-in scrolling layout configured to mimic niri's scrollable tiling (see `modules/window-manager/SPEC.md` for the niri-equivalent keybinds), with Vicinae launcher (wifi, bluetooth, monitor extensions)
- Development tooling with direnv, git, and SSH agent
- Firefox browser (home-manager managed, `my.firefox.enable`) with Slack and other communication apps
- Alacritty terminal with Bash shell and Starship prompt
- Disk encryption enabled for security
- Fingerprint support is configured but switched off (`my.fingerprint.enable = false`)
- `my.profiles.laptop` (implies workstation): touchpad, backlight, TLP power management, battery notifications, audio, bluetooth, printing, firmware updates
- Battery monitoring and power management (TLP, see `modules/power-management/SPEC.md`). The diagnostic posture that chased the hard power-offs — AC capped to `low-power` / `low` amdgpu DPM plus `forensics.enable` — has been **retired**, because the telemetry it collected identified the cause: the pack reports empty at 0.5 Wh and then runs for another 100 minutes, i.e. a degraded cell stack *and* a fuel gauge that has lost calibration, so reported percentages and time-remaining figures are meaningless. **The pack is the outstanding hardware item**; BIOS 1.63 is still well behind current.
- Tuned for a light login: nothing autostarts, and Docker (rootful) and CUPS start on demand rather than at boot. Measured idle draw is ~3.4 W with the screen off against ~10 W with the panel at full brightness, so the display dominates everything else on this machine.
- Docker for containerized development — rootless only at boot; the rootful daemon is socket-activated (see `modules/docker/SPEC.md`)
- Offline media for travel: `media` (mpv + yt-dlp) for DRM-free sources. **Waydroid is currently disabled** (see below); when it was on it provided Netflix's Android app for offline downloads — SD only, with Disney+/HBO Max hard-blocked (see `modules/waydroid/SPEC.md`)
- Bluetooth and printer support; `printers.remoteDiscovery = false` drops `cups-browsed` so `cupsd` stays socket-activated instead of running from boot
- LocalSend for local file sharing (with CLI)
- 3D printing toolchain: PrusaSlicer, OpenSCAD (dev snapshot), FreeCAD (`my.printing-3d` with `cad.enable`, see `modules/printing-3d/SPEC.md`)
- SMB network share browsing in Thunar (GVFS + Avahi/mDNS discovery)
- No emulation client or Syncthing on this work laptop (dropped for lightness)
- Colemak keyboard layout
- Stylix theming (gruvbox dark via the theming module's `my.theming.*` picker) with Banana cursor
- sops-nix integration: SSH keys delivered from the external `nix-vault` flake input; OpenSSH and pcscd auto-enabled by `my.sops`
- SSH client config generated from the registry (`modules/ssh`): `ssh controller` / `ssh desktop` connect as `betongsuggan` with the `bits` key, without YubiKey touch; the GitHub hosts are declared in the user file
- `betongsuggan@controller`'s SSH key is authorized on `birgerrydback` so the controller host can SSH back into bits (`sshFrom` on this account in `lib/default.nix`); the same registry entries generate the `Host controller` / `Host desktop` client blocks
- Firewall with ports open for LocalSend (53317), the dev server (8080) and 3010
- `/etc/hosts` maps `bits.execute-api.localhost.localstack.cloud` to localhost for LocalStack API Gateway development

## Notes

- Hardware: AMD CPU with `amd_pstate=active` frequency scaling and microcode updates
- Kernel: Linux 6.18 with laptop-mode power optimizations (`vm.laptop_mode=5`)
- **Waydroid is disabled as of 2026-09-17.** It crashed Hyprland twice in three hours: Waydroid's gralloc allocates Android surfaces on the discrete Navi 24 (`gralloc.gbm.device=/dev/dri/renderD128` in `/var/lib/waydroid/waydroid_base.prop`) while Hyprland composites on the Rembrandt iGPU (`renderD129`), so every surface crosses GPUs as a DCC-compressed dmabuf. That reset the iGPU, and Hyprland aborts on `GL_UNKNOWN_CONTEXT_RESET` because it has no reset-recovery path. Re-enabling requires first repointing gralloc at the iGPU render node — `gralloc.gbm.device=/dev/dri/by-path/pci-0000:67:00.0-render` (by-path, because `renderD*` numbering is not stable across boots)
- Waydroid pulls in `psi=1` on the kernel command line, so toggling it either way needs a reboot, not just a `nixos-rebuild switch`; it also forces `pkgs.waydroid-nftables` because 6.18 no longer ships `ip_tables`
- Boot: systemd-boot (secure boot not enabled)
- Firmware updates via fwupd (deferred to on-demand start)
- When Waydroid is enabled, its `waydroid-container` unit is deliberately not wanted by `multi-user.target`; use `waydroid-up`
- Timezone: Europe/Stockholm
