# Island Pi

Raspberry Pi 3 Model B v1.2 (aarch64, 1 GB RAM) — the always-on host at the summer place. Not a second controller: it runs none of the singleton fleet services (headscale, nextcloud, vaultwarden, smb, …). Its jobs:

- Always-on tailnet SSH node at the summer place
- Deliberately **not** a subnet router (see "Subnet router" below)
- **DNS filter for the summer LAN** (`my.dns-filter`, blocky without the query log): the same telemetry blocking as home for the Samsung TV, the Nest Mini and the AC there, once the summer router hands out `192.168.51.5` as DNS
- **Wake-on-LAN relay** for `island-stationary` (`ssh island-pi wake-island-stationary`); controller's restic backups wake it the same way through the `wake` account (`ssh wake@island-pi wake-island-stationary`, forced command, see `modules/common/SPEC.md`)

## The one rule: this host never builds or evaluates nix

The Pi is far too slow (and too small — 1 GB RAM) to evaluate or build this flake. Every deploy runs from another fleet machine:

```bash
nixos-rebuild switch --flake .#island-pi --target-host root@island-pi.ts.rydback.net
```

With `--target-host` and no `--build-host`, evaluation and building happen on the deploying machine; only the closure is copied over SSH. Any x86 fleet host works as the deployer: `modules/common` enables `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` on all x86_64 hosts (active after that host's next rebuild). Most of the aarch64 closure substitutes straight from cache.nixos.org; only evaluation and small local derivations run under qemu emulation.

Deploying as root is what makes unsigned closure copies acceptable to the Pi's nix-daemon (no `trusted-users` needed). Root and `betongsuggan` authorize every admin identity's key in the fleet (`lib.fleetPeers`), so deploys work from any machine, in both onboarding stages.

## Hardware / boot

- U-Boot + `generic-extlinux-compatible`, mainline kernel (default `linuxPackages`). No systemd-boot (`my.common.systemd-boot = false`) and no secure boot.
- SD layout comes from the flake-built image (`packages.aarch64-linux.island-pi-sd-image`, nixpkgs `sd-image-aarch64.nix`): vfat `FIRMWARE` partition (Pi firmware + U-Boot) + ext4 `NIXOS_SD` root. Deploys only rewrite `/boot/extlinux`; the firmware partition is never touched. `/boot/firmware`'s mount options are `mkForce`d so the image's fstab matches the deployed one (a merged duplicate list made the first deploy's switch fail on `boot-firmware.mount`; images flashed before this fix need one reboot after the first deploy).
- zram swap (zstd, 100% of RAM) instead of SD-card swap; journald capped at 100M. blocky (the DNS filter) is the one memory-hungry service; the query log and monitoring stay off here.
- Wired ethernet with plain DHCP — no NetworkManager.

## Deployer prerequisites (read before the first install)

Any x86 fleet host can build the image and deploy, with two conditions:

1. **aarch64 emulation must be active on the deployer.** `modules/common` turns it on for every x86 host, but only after that host has been rebuilt since. Check with `ls /proc/sys/fs/binfmt_misc | grep aarch64`; if nothing prints, `sudo nixos-rebuild switch` the deployer first.
2. **Stage 2 needs `nix-vault`.** The deploy evaluates the flake, and the flake's `nix-vault` input is fetched from controller over the tailnet (`git+ssh://git@controller.ts.rydback.net/...`). A deployer that is **not on the tailnet** (`private-laptop` today) cannot fetch it. Either onboard that deployer first (`modules/home-network/SPEC.md`), or evaluate against a working clone copied onto it: `scp -r ~/nix-vault <deployer>:` from any onboarded host over the LAN, then add `--override-input nix-vault path:$HOME/nix-vault` to every `nixos-rebuild` / `nix build` below. Stage 1 (image, flash, first boot, host key) needs no secrets and works from any deployer.

## Open items (on-site at the summer place)

Status 2026-10-22: installed at the summer place and came up on its own — LAN `192.168.51.5`, tailnet `island-pi` (100.64.0.8), direct connection to a laptop on the same LAN. Left to do (nix-home card 103):

- [ ] **Host key backup** (if not done before leaving): `ssh root@island-pi.ts.rydback.net 'tar -C /etc/ssh -czf - ssh_host_ed25519_key ssh_host_ed25519_key.pub' > island-pi-hostkey.tgz`, stored privately. Needed to re-flash without re-enrolling (see Recovery).
- [x] **Check the subnet:** `192.168.51.0/24`, recorded in `lib.hosts.island-pi.lan.subnet` (2026-10-22).
- [x] **Deployed** from bits over the tailnet (2026-10-22): `wake` account and `wake-island-stationary` present; headscale lists no route for island-pi.
- [x] **Controller** rebuilt with the registry subnet and the relay wake (2026-10-22).
- [ ] **DNS filter:** on the summer ASUS, LAN → DHCP Server → DNS Server 1 = `192.168.51.5`, DNS Server 2 empty (`modules/dns-filter/SPEC.md`, "Router setup"). Then from island-stationary `resolvectl query lgsmartad.com` must answer `0.0.0.0`. Check memory on the Pi after the first day: `free -m` and `systemctl status blocky` (blocky with the hagezi list is the biggest thing on this host; trim `my.dns-filter.blocklists` if it swaps).
- [ ] **Wake-on-LAN:** confirm WoL is enabled in island-stationary's BIOS (`wakeOnLan` is already on in its config), shut it down, then `ssh island-pi wake-island-stationary` and `ssh island-stationary.ts.rydback.net`.
- [ ] Remove this section and update the status once done.

## First install (SD image)

On any x86 host with binfmt active (rebuild it once first):

```bash
nix eval .#nixosConfigurations.island-pi.config.system.build.toplevel.drvPath  # cheap sanity check
# Full attribute path required: bare `.#island-pi-sd-image` only searches the
# current system's packages (x86_64), but the image is an aarch64 derivation.
nix build .#packages.aarch64-linux.island-pi-sd-image   # tens of minutes; image assembly runs under qemu
zstd -d result/sd-image/*.img.zst -o /tmp/island-pi.img
sudo dd if=/tmp/island-pi.img of=/dev/sdX bs=4M conv=fsync status=progress
```

First boot auto-expands the root partition. Do the first boot on the home LAN before transporting the Pi.

## Onboarding (headless variant — no bootstrap mode)

The standard runbook (`modules/home-network/SPEC.md`) uses `mode = "bootstrap"` so a new host can fetch `nix-vault` itself. island-pi never evaluates nix, so it skips that entirely: stage 1 (plain LAN ssh, as flashed) → stage 2 (`onboarded`). The YubiKey is only needed for sops-editing nix-vault on the operator machine.

1. **First boot on home LAN.** Find the DHCP address, then:
   `ssh betongsuggan@<ip> cat /etc/ssh/ssh_host_ed25519_key.pub`
2. **Register in `lib/default.nix`:** fill in the island-pi `ssh.host` entry. Commit, push.
3. **Controller:** `git pull && sudo nixos-rebuild switch --flake .#controller` (trusts the new key via `allSshKeys`), then mint a preauth key: `sudo headscale preauthkeys create --user birger --reusable --expiration 8760h`.
4. **nix-vault:** convert the host key (`ssh-to-age`), add the `age1…` recipient to `.sops.yaml`, create `secrets/island-pi.yaml` with `services.headscale-preauthkey`, `sops updatekeys`, commit, push.
5. **Stage 2 flip in `system.nix`:** uncomment `my.home-network` (onboarded) and `my.sops`. `services.openssh.openFirewall = true` stays: it no longer conflicts with the tailnet defaults and keeps LAN SSH as the recovery path. Then `nix flake update nix-vault` and deploy over LAN:
   `nixos-rebuild switch --flake .#island-pi --target-host root@<lan-ip>`
6. **Reboot the Pi once while you still have physical access** — verifies the lean deployed initrd (without the image's all-hardware profile) still mounts the SD root.

## Subnet router

The Pi does **not** advertise the summer-place LAN (decided 2026-10-22, nix-home card 102): nothing there needs reaching from the tailnet. island-stationary is a tailnet member reached by name, and waking it is `ssh island-pi wake-island-stationary`.

The LAN is `192.168.51.0/24` (`lib.hosts.island-pi.lan.subnet`), an uncommon range, so advertising it would be safe when the need arises. It would not be for a default range: tailnet members accept advertised routes (`--accept-routes`, all or nothing per host) behind a policy rule that beats the local network, and a route for `192.168.1.0/24` would have hijacked gateway, DNS and captive-portal traffic on every guest or office network using it, which is how the question came up. Should the summer router ever be reset to such a default, renumber it before advertising.

To advertise: controller already auto-approves every registry `lan.subnet`; set `my.home-network.advertiseRoutes = [ self.lan.subnet ]` in this host's `system.nix` and deploy the Pi (routes are re-applied on every tailscaled start, `set-flags`). Tailnet→LAN only: devices must run Tailscale to use the route.

## Wake-on-LAN relay

`wake-island-stationary` (a one-line wrapper around `wakeonlan`, generated by `modules/common` because `lib.hosts.island-stationary.wol.relay = "island-pi"`) broadcasts a magic packet to island-stationary's MAC from `lib/default.nix`. Usage from anywhere on the tailnet:

```bash
ssh island-pi wake-island-stationary
# then, once it's up:
ssh island-stationary.ts.rydback.net
```

The existing `wake-proxy` module was deliberately not used: it transparently fronts TCP services on the *same* port, which would collide with the Pi's own sshd on 22. Wake-then-connect-directly fits the need; `wake-proxy` can still be enabled later for non-22 ports (e.g. game streaming).

island-stationary side: `networking.interfaces.<nic>.wakeOnLan.enable = true` plus WoL enabled in its BIOS.

## Recovery

- Port 22 stays open on the LAN permanently (key-only) — if the tailnet is down, ssh via the summer-place LAN.
- Re-flash: build the image again, and before first boot copy the saved `/etc/ssh/ssh_host_ed25519_key{,.pub}` onto the SD root partition's `/etc/ssh/` — the host keeps its age identity and tailnet enrollment survives.

## Notes

- Timezone: Europe/Stockholm. stateVersion 26.05.
- Deploys copy the closure over whatever address `--target-host` names: use the tailnet FQDN (`island-pi.ts.rydback.net`) off-LAN, the DHCP address on-LAN.
- Serial console: the image's `config.txt` has `enable_uart=1` — a USB-TTL cable on the GPIO header gives a console if first boot doesn't come up.
