# Bits

Work laptop for Birger Rydback at Bits: a **Framework Laptop 13 Pro** (Intel Core Ultra X9, Panther Lake, Arc B390 integrated graphics on the `xe` driver, 32 GB RAM) running NixOS with the Hyprland Wayland compositor (scrolling layout mimicking niri), configured for software development and daily office use. It replaced an AMD laptop (Rembrandt + RX 6500M) under the same host name and identity; that machine's history is in git before the Framework move.

## Key Features

- Hyprland compositor using the built-in scrolling layout configured to mimic niri's scrollable tiling (see `modules/window-manager/SPEC.md` for the niri-equivalent keybinds), with Vicinae launcher (wifi and bluetooth extensions; monitors through monitormenu)
- Development tooling: toolchains (Go, Node, Python, Kotlin) and cloud tools (LocalStack, AWS CLI/CDK, Terraform) come from each repository's own dev shell (`flake.nix` + `.envrc` with `use flake`, cached by nix-direnv; `~/Development/cloud` has one), not from the system: `my.development` keeps only gh, Claude Code and opencode (`infra.enable = false`, no language flags). The editor keeps its Go and TypeScript language servers (`my.editor.languages`); Kotlin is gone from the editor. Plus direnv, git and the SSH agent
- Firefox browser (home-manager managed, `my.firefox.enable`) with Slack
- Alacritty terminal with Bash shell and Starship prompt
- Disk: disko (`disko.nix`) on the internal NVMe: 1 GiB ESP, then one LUKS2 container (discard on; unlocked by TPM2 + PIN, the passphrase is the recovery key) holding LVM with a 34 GiB swap LV (hibernation target, RAM + 2 GiB) and the ext4 root. zswap (zstd, 20 % of RAM) is the compressed cache in front of the swap LV; the laptop profile's zram is off here, so pages aren't compressed twice
- Fingerprint reader (Framework's Goodix sensor, libfprint's built-in driver: `driver = "generic"`; confirm the USB id on the machine): fingerprint or password at the same prompt for login, sudo and polkit; hyprlock reads it natively
- `my.profiles.laptop` (implies workstation): touchpad, backlight, TLP power management, battery notifications, audio, bluetooth, printing, firmware updates
- Battery monitoring and power management (TLP and thermald for Intel, `cpuVendor`/`gpuVendor = "intel"`, see `modules/power-management/SPEC.md`)
- Tuned for a light login: nothing autostarts, Docker (rootless and rootful), CUPS, sshd and fwupd start on demand, and Hyprland drops blur/shadows on battery. Idle draw to be measured on the Framework (`powertop`); on the old laptop the display dominated everything else
- Docker for containerized development — rootless only at boot; the rootful daemon is socket-activated (see `modules/docker/SPEC.md`)
- Offline media for travel: `media` (mpv + yt-dlp) for DRM-free sources. **Waydroid is currently disabled** (see below); when it was on it provided Netflix's Android app for offline downloads — SD only, with Disney+/HBO Max hard-blocked (see `modules/waydroid/SPEC.md`)
- Bluetooth and printer support; the laptop profile drops `cups-browsed` so `cupsd` stays socket-activated instead of running from boot
- Taildrop (`my.taildrop`, on by default for the admin user): Mod+Shift+S sends the clipboard to any tailnet device, phones included; received files land in `~/Downloads/taildrop` and received clipboards go straight to the clipboard. The admin user is the host's tailscale operator
- Project tracker CLI (`my.deck`, Nextcloud user `birger`): `deck` reads and updates the Nextcloud Deck boards on controller; the app password comes from the vault (`common.yaml` → `/run/secrets/deck-token-birgerrydback`). Claude Code uses it through `.claude/skills/deck`. See `modules/deck/SPEC.md`
- SMB network share browsing in Thunar (GVFS + Avahi/mDNS discovery)
- Not on this machine for now (dropped for lightness, each one block to bring back): gaming (Steam, Battle.net), the Moonlight client, 3D printing/CAD (FreeCAD, PrusaSlicer, OpenSCAD), emulation, Syncthing, LocalSend
- Colemak keyboard layout
- Theming with the kanagawa scheme (`my.theming.scheme`: stylix apps, the editor's kanagawa.nvim, waybar/Hyprland colors) and Banana cursor
- Editor: nvim (`modules/editor`) with Nix, Go, Kotlin and TypeScript support
- sops-nix integration: SSH keys delivered from the external `nix-vault` flake input; OpenSSH and pcscd auto-enabled by `my.sops`
- SSH client config generated from the registry (`modules/ssh`): `ssh controller` / `ssh desktop` connect as `betongsuggan` with the `bits` key, without YubiKey touch; the GitHub hosts are declared in the user file
- `betongsuggan@controller`'s SSH key is authorized on `birgerrydback` so the controller host can SSH back into bits (`sshFrom` on this account in `lib/default.nix`); the same registry entries generate the `Host controller` / `Host desktop` client blocks
- Firewall with ports open for the dev server (8080) and 3010. No LocalSend (dropped 2026-10-31; Taildrop covers file sharing)
- `/etc/hosts` maps `bits.execute-api.localhost.localstack.cloud` to localhost for LocalStack API Gateway development

## Notes

- Hardware: Intel Core Ultra X9 (Panther Lake) with microcode updates; graphics on the `xe` kernel driver (`my.graphics.intel.generation = "xe"`, early KMS loads `xe`), VA-API through iHD
- Framework's NixOS module: `nixos-hardware.nixosModules.framework-intel-core-ultra-series3` (Framework's NixOS guide asks for it). It adds the community EC kernel module (`cros_ec`, `framework-laptop-kmod`) and `framework-tool`/`ectool` (charge limit, LEDs, firmware versions), the ambient light sensor (`hardware.sensor.iio`), `nvme.noacpi=1`, the Ethernet expansion card autosuspend rule and `acpilight`. Its GPU defaults (i915 in the initrd, both VA-API drivers, intel-ocl) are overridden with `hardware.intelgpu = { driver = "xe"; vaapiDriver = "intel-media-driver"; }`; it still adds `intel-compute-runtime` (OpenCL, ~386 MiB) unconditionally. Its speaker EQ (`hardware.framework.laptop13.audioEnhancement`) stays off: it is tuned for the classic chassis, not the Pro
- Kernel: `linuxPackages_latest` (7.2 at the move): Panther Lake support and Xe3 fixes keep landing (Phoronix measured gains through 7.3), so this host tracks the newest kernel rather than an LTS
- Boot: lanzaboote Secure Boot (`my.secure-boot`), signed UKIs on the 1 GiB ESP, 10 generations; keys in `/var/lib/sbctl`; loader timeout 0 (hold a key during boot for the menu)
- Hibernate: `boot.resumeDevice = /dev/vg/swap` (set by disko); works with lanzaboote as long as kernel lockdown stays off (NixOS default). `suspend-then-hibernate` on lid close is not configured yet
- **Waydroid is off.** It was only used for offline Netflix downloads. On the previous laptop it crashed Hyprland (Android surfaces crossing from the discrete GPU to the iGPU); this machine has one GPU, so that reason is gone, but nothing has been tested. Waydroid pulls in `psi=1` on the kernel command line, so toggling it needs a reboot
- Lean boot/shutdown/rebuild (2026-10-31, card 148). Baseline: 39.7 s cold boot (firmware 13.7, loader 1.8, kernel 0.8, initrd 18.2 incl. typing the LUKS passphrase and the Argon2 KDF, userspace 5.2); shutdown ~5 s with outliers of 11 s and 92 s (a session scope with nvim hung until the 90 s default stop timeout, user services restart-looping meanwhile); evaluation ~35 s cold. Now: stop timeout 10 s for the system and user managers (`DefaultTimeoutStopSec`), loader timeout 0, NixOS manual and the Home Manager options manpage off (~7 s less evaluation; `man` for tools stays). Login stays getty + fingerprint (no autologin: work laptop)
- Firmware updates via fwupd (deferred to on-demand start); Framework says to use `fwupdmgr`, not a GUI updater
- Timezone: Europe/Stockholm
- **Closure**: re-measure after the first switch on the Framework (`nix path-info -S /run/current-system`; `nix path-info -rs /run/current-system | sort -k2 -n | tail` lists the big ones). The old laptop was at 25.63 GiB on 2026-10-31 with gaming, Moonlight and CAD still on.
- The vicinae file indexer is off declaratively (`programs.launcher.vicinae.fileIndex.enable`, default false → `autoIndexing: false` in the store-linked settings.json); nothing to toggle in the UI.


## Swap-day runbook (old laptop → Framework)

The Framework takes over the old laptop's identity (host SSH key and Tailscale state), so the registry entry, the sops secrets (`nix-vault` `secrets/bits.yaml`, encrypted to the host key's age key) and the tailnet IP 100.64.0.1 keep working without changes.

1. On the old laptop: copy `/etc/ssh/ssh_host_ed25519_key{,.pub}` and `/var/lib/tailscale/` somewhere safe (USB stick, or over the tailnet). Leave the old laptop as it is until the new one works.
2. Framework firmware: Secure Boot in setup mode (clear the factory keys).
3. Boot the NixOS installer, get the repo (this branch until the PR is merged), check the disk name with `lsblk` against `disko.nix`, then format: `sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#bits` (asks for the new LUKS passphrase: make it long and random and store it in Bitwarden; after step 7 it is only the recovery key).
4. Put the host key into `/mnt/etc/ssh/` (mode 600 for the private key) and the Tailscale state into `/mnt/var/lib/tailscale/`.
5. `nixos-generate-config --no-filesystems --show-hardware-config` and compare `boot.initrd.availableKernelModules` with `system.nix`.
6. `sudo nixos-install --flake .#bits`, reboot (Secure Boot still off). Then `sudo sbctl create-keys && sudo sbctl enroll-keys --microsoft`, `nixos-rebuild switch`, and turn Secure Boot on in the firmware; `sbctl status` and `bootctl status` confirm it.
7. With Secure Boot on, enrol the TPM unlock: `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/disk/by-partlabel/disk-main-luks` (choose the PIN). `disko.nix` already sets `tpm2-device=auto` in crypttab, so the next boot asks for the PIN; the TPM releases the key only for this Secure Boot state and locks out after repeated wrong PINs. `sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-main-luks` should list a `password` and a `tpm2` slot. If the TPM ever refuses (Secure Boot keys changed, firmware update that changes PCR 7), the passphrase prompt appears; then wipe and re-enrol the TPM slot: `--wipe-slot=tpm2` with the same command.
8. Restore `/home/birgerrydback` from the old laptop over the tailnet (`rsync -aHAX`); `~/Games` can stay behind while gaming is off.
9. Re-enroll fingerprints (`fprintd-enroll`).
10. Firmware boot options: disable network (PXE) boot and any boot device you don't use, so POST is short. Then update the firmware: `fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update` (Panther Lake BIOS was "coming soon" on LVFS at the move; `framework_tool --versions` shows what is installed). Optional: `sudo framework_tool --charge-limit 80` to spare the battery on the desk
11. Check: `ssh controller`, `tailscale status` (same IP), `ls /run/secrets`, `vulkaninfo --summary` (ANV on the B390), `systemctl hibernate` + resume, `cat /sys/module/zswap/parameters/enabled`, suspend/resume on battery, and `systemd-analyze` against the old laptop's 39.7 s (firmware 13.7, loader 1.8, kernel 0.8, initrd 18.2, userspace 5.2), `swapon` (only the swap LV, no zram), `lsmod | grep cros_ec`, and battery life with TLP against power-profiles-daemon (Framework recommends PPD on recent Intel; switch only if it measures better).
12. Merge the PR and move its Deck card to Done; the old laptop can be wiped.
