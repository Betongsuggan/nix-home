# Island Stationary

Personal gaming and development desktop with AMD Ryzen CPU and NVIDIA RTX 2070 GPU. Mirrors the desktop setup with two user sessions: `betongsuggan` for general desktop use and development, and `gamer` as a dedicated auto-login gaming session.

## Key Features

- `my.profiles.gaming-station` (implies workstation): autologin `gamer` session, zen kernel and gaming tuning, gamemode, secure boot, DualSense wake, restic target for controller (see `modules/profiles/SPEC.md`); this file only keeps what is specific to this machine
- Two-user setup: `betongsuggan` (development/daily use) and `gamer` (dedicated gaming)
- Gamer user auto-logs in on TTY1 and launches Hyprland automatically via `start-hyprland` (the upstream watchdog: relaunches Hyprland in safe mode after a crash rather than leaving a bare TTY)
- Hyprland compositor on both users; the single output and its mode are pinned in `session.nix`, shared by both users (see Notes)
- NVIDIA RTX 2070 GPU with proprietary drivers
- Console-mode with Gamescope session for Steam Deck-like experience
- Steam Big Picture auto-start on gamer session with SteamOS 3 features
- PS5 DualSense controller support with rumble and MangoHud toggle
- GameMode with CPU renicing for gaming performance
- MangoHud overlay with detailed mode and vkBasalt post-processing
- Steam from `programs.steam` (the games module's NixOS half, since gamer sets `my.games.enable`), with Proton-GE through `programs.steam.extraCompatPackages` and the SteamOS sysctls from nix-gaming's `platformOptimizations`
- NVIDIA-optimized environment variables (shader caching, NVAPI)
- Zen kernel optimized for desktop/gaming, pinned to 7.0.9 (see Notes)
- ZRAM swap (zstd, 50% memory) for memory efficiency
- CPU governor set to performance mode
- Development environment on betongsuggan user with Docker support
- Vicinae launcher with wifi, bluetooth, and monitor extensions on both users
- Chromium, communication apps, and LocalSend on both users
- Taildrop (`my.taildrop`, on by default for the admin user): Mod+Shift+S sends the clipboard to any tailnet device, phones included; received files land in `~/Downloads/taildrop` and received clipboards go straight to the clipboard. The admin user is the host's tailscale operator
- Alacritty terminal with Bash shell and Starship prompt
- Bluetooth with wake support for DualSense controller
- Secure boot via Lanzaboote
- Firewall with ports for LocalSend
- Tailnet membership via `home-network` module, `onboarded` mode. Joins under its real hostname with the sops-decrypted preauth key from `nix-vault/secrets/island.yaml`. Off the home LAN, so `controller` is reached only over the tailnet — the user SSH `matchBlock` targets `controller.ts.rydback.net` and offers both `~/.ssh/id_rsa` (sops-provisioned) and the FIDO resident key from the onboarding pass.
- Restic backup target: receives snapshots from controller into `/var/lib/restic-repos/controller/repo` via chrooted SFTP user `restic-controller` (key sourced from `lib/default.nix`). Off-site copy in the interim backup topology — requires island-stationary to be onboarded to the tailnet for controller to reach it. See `modules/restic-target/SPEC.md`.
- Wake-on-LAN: the wired NIC has `wakeOnLan.enable = true` so the always-on `island-pi` host at the same location can wake this machine remotely (`ssh island-pi wake-island-stationary`, then ssh island-stationary directly). The MAC is registered as `wol.mac` in `lib/default.nix`; WoL must also be enabled in BIOS. The NIC is `eth0` (Realtek r8169), which only wakes the machine when it is cabled: the host otherwise runs on Wi-Fi.

## TODO (next on-site visit): wire up emulation for gamer

The desktop's retro/Switch emulation setup (per-ROM Steam tiles, ROM/BIOS mounts, save
sync — see `modules/games/SPEC.md` and `modules/emulation-client/SPEC.md`) is not wired
here yet. To mirror it:

1. **`system.nix`**: enable the mounts —
   `emulation-mounts = { enable = true; server = inputs.self.lib.tailnet.fqdn "controller"; users = [ "betongsuggan" "gamer" ]; };`
2. **`user-gamer.nix`**: enable `my.games.emulators` (+ `my.games.emulators.steamShortcuts`,
   and `switch` if wanted) and
   `emulation-client = { enable = true; server.address = inputs.self.lib.tailnet.fqdn "controller"; };`
3. **Register the Syncthing ID**: after the first rebuild, run `syncthing --device-id`
   as `gamer` on this machine and add it in `lib/default.nix` under
   `hosts.island-stationary.users.gamer.syncthing.id`, then rebuild **controller** so it
   accepts the peer.
4. If tiles are wanted, mirror the desktop's `steamgriddb-api-key` sops secret (owner
   `gamer`) for artwork, and note this host has no Sunshine/Hyprland-over-stream setup —
   the launcher's hyprctl fullscreen poll is harmless locally, but verify fullscreen
   behavior on the local session.

Prerequisite: the host must be onboarded to the tailnet (it is — `home-network` mode
`onboarded`), since controller serves Samba/Syncthing tailnet-only.

## Differences from desktop

- NVIDIA RTX 2070 GPU instead of AMD RDNA4 (no AMD GPU env vars, no undervolting, no mesa unstable overlay)
- No game streaming server (Sunshine)
- No emulation server (Syncthing/WireGuard)
- One pinned ultrawide output instead of desktop's two-screen HDR/VRR layout

## Notes

- Hardware: AMD Ryzen CPU with NVIDIA RTX 2070 GPU
- Kernel: Zen kernel with `mitigations=off` and `preempt=full` for maximum gaming performance

### The monitor mode is pinned, because the EDID lies

The BenQ EX3501R is a 3440x1440 ultrawide, but its EDID also advertises 3840x2160 (plus
several other) modes the panel cannot actually display. Unpinned, the window-manager
module's catch-all rule (`,highres,auto,1`) picks the largest *advertised* mode and the
session comes up at 3840x2160@59.94.

`hosts/island-stationary/session.nix` pins the real panel mode (3440x1440@99.982, the
monitor's 100 Hz mode) at scale 1, and is imported by both `user-betongsuggan.nix` and
`user-gamer.nix` so the two sessions cannot drift apart — the same split desktop uses.

It is keyed by `desc:` rather than a connector name. The panel reaches the GPU through the
RTX 2070's USB-C (VirtualLink) port, which the kernel enumerates as the unnamed connector
`Unknown-2` (`/sys/class/drm/card1-Unknown-2`) — a name tied to probe order that carries no
meaning, whereas the description is the panel's own identity. Hyprland matches a `desc:`
prefix against the `description` field of `hyprctl monitors`.

### Peripheral topology and the kernel pin

The keyboard and mouse receivers live in the BenQ EX3501R's internal USB hub, and that hub
reaches the machine only through the monitor's USB-C cable into the RTX 2070's USB-C
(VirtualLink) port — so all HID input depends on the GPU's own xHCI controller
(`0a:00.2`). There is no alternative routing on this desk; treat this as a fixed constraint
when changing kernel or GPU configuration.

### USB disconnects: the actual discriminator is the GPU's root-hub port

Peripherals behind that hub disconnect intermittently. The GPU's xHCI root hub exposes **two
ports**, and which one the monitor's hub lands on tracks the fault exactly:

| hub enumerates as | kernel | sampled | disconnects |
|-------------------|--------|---------|-------------|
| `usb 3-1` | 7.0.9-zen1 | May 23 → Aug 11 (~2.5 months) | **0** |
| `usb 3-1` | 7.0.9-zen1 | 30 min | **0** |
| `usb 3-2` | 7.0.9-zen1 | 20 h | 1 |
| `usb 3-2` | 7.1.5-zen1 | 32 min | 4 |
| `usb 3-2` | 7.1.5-zen1 | 32 min | 5 |
| `usb 3-2` | 7.0.9-zen1 | 5 min | 4 |

**The kernel is not the cause.** The pinned 7.0.9 build is the byte-identical store path
(`zash60j4si01w8zijfchf37zspk5wgaj-linux-zen-7.0.9`) that ran the 2.5-month clean boot, and it
still drops on port `3-2`. The same hub, receiver and monitor are also stable on the `bits`
host. Port `3-1` is the only configuration that has ever been clean.

Failure mode varies — sometimes only the Logitech receiver (`3-2.2`) drops, sometimes the
whole link goes (`3-2` plus every child, plus `4-2` on the SuperSpeed side of the same
controller) — which is consistent with a marginal physical link rather than a driver bug.

**If disconnects appear: reseat the monitor's USB-C cable at the GPU, flipping it 180°, then
check `lsusb -t` shows the hub on `Bus 003.Port 001`.** A Type-C receptacle carries a
USB 2.0 pair per orientation, so flipping the connector moves which root-hub port is used.

`ucsi_ccg` and `typec_ucsi` are blacklisted because 7.1.x fails to initialise the GPU's
Cypress CCGx Type-C controller. This is unrelated to the disconnects (it does not occur on
7.0.9, which drops anyway) but the probe is broken either way, and DP alt mode is negotiated
by the controller's own firmware.

### The kernel pin (provisional)

`boot.kernelPackages` is pinned to zen 7.0.9 via the `nixpkgs-kernel` flake input rather than
tracking `pkgs.linuxPackages_zen`. **This pin did not fix the disconnects and is retained only
so the cable change can be tested against one variable at a time — it should be reverted once
port `3-1` is confirmed stable.** Mechanics, for whoever unpins:

- 7.1.x fails to initialise the GPU's Cypress CCGx Type-C controller
  (`ucsi_ccg 0-0008: error -ETIMEDOUT: PPM init failed`), which 7.0.9 does not log.
- Only the **kernel derivation** is taken from the pinned input; it is then wrapped in
  `pkgs.linuxPackagesFor` so the surrounding module set (and therefore the NVIDIA driver,
  which `modules/graphics` derives from `config.boot.kernelPackages.nvidiaPackages.stable`)
  still comes from 26.05 — currently `nvidia-kernel-modules-595.71.05-7.0.9`. Taking the
  pinned `linuxPackages_zen` wholesale instead pulls in its 580.x driver, which lacks the
  `.mod` attribute the 26.05 nvidia module expects, and fails to evaluate.
- The pinned tree is `import`ed with `config.allowUnfree = true` rather than read from
  `legacyPackages`: out-of-tree modules build with the *kernel's* stdenv, so the pinned
  tree's `check-meta` is what vets the unfree NVIDIA derivation, and a bare `legacyPackages`
  carries a default config that rejects it.

To unpin: delete the `boot.kernelPackages` override here — `my.profiles.gaming-station` already
sets `pkgs.linuxPackages_zen` as an `mkDefault`, which this host overrides — then drop the
`nixpkgs-kernel` input from `flake.nix` and rebuild. Keep the `blacklistedKernelModules`
entries — they only matter on 7.1.x.

- NTFS filesystem support enabled for accessing Windows drives
- Timezone: Europe/Stockholm
- Colemak keyboard layout
