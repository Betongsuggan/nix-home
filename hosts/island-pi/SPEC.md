# Island Pi

Raspberry Pi 3 Model B v1.2 (aarch64, 1 GB RAM) — the always-on host at the summer place. Not a second controller: it runs none of the singleton fleet services (headscale, nextcloud, vaultwarden, smb, …). Its jobs:

- Always-on tailnet SSH node at the summer place
- Tailscale **subnet router** advertising the summer-place LAN
- **Wake-on-LAN relay** for `island-stationary` (`ssh island-pi wake-island-stationary`)

## The one rule: this host never builds or evaluates nix

The Pi is far too slow (and too small — 1 GB RAM) to evaluate or build this flake. Every deploy runs from another fleet machine:

```bash
nixos-rebuild switch --flake .#island-pi --target-host root@island-pi.ts.rydback.net
```

With `--target-host` and no `--build-host`, evaluation and building happen on the deploying machine; only the closure is copied over SSH. Any x86 fleet host works as the deployer: `modules/common` enables `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` on all x86_64 hosts (active after that host's next rebuild). Most of the aarch64 closure substitutes straight from cache.nixos.org; only evaluation and small local derivations run under qemu emulation.

Deploying as root is what makes unsigned closure copies acceptable to the Pi's nix-daemon (no `trusted-users` needed). Root and `betongsuggan` authorize every human user key in the fleet (`lib.allPeersFor`), so deploys work from any machine, in both onboarding stages.

## Hardware / boot

- U-Boot + `generic-extlinux-compatible`, mainline kernel (default `linuxPackages`). No systemd-boot, no lanzaboote (module imported for type-check only, never enabled).
- SD layout comes from the flake-built image (`packages.aarch64-linux.island-pi-sd-image`, nixpkgs `sd-image-aarch64.nix`): vfat `FIRMWARE` partition (Pi firmware + U-Boot) + ext4 `NIXOS_SD` root. Deploys only rewrite `/boot/extlinux`; the firmware partition is never touched.
- zram swap (zstd, 100% of RAM) instead of SD-card swap; journald capped at 100M.
- Wired ethernet with plain DHCP — no NetworkManager.

## First install (SD image)

On any x86 host with binfmt active (rebuild it once first):

```bash
nix eval .#nixosConfigurations.island-pi.config.system.build.toplevel.drvPath  # cheap sanity check
nix build .#island-pi-sd-image        # tens of minutes; image assembly runs under qemu
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
5. **Stage 2 flip in `system.nix`:** uncomment `home-network` (onboarded), `sops-secrets`, and `tailscale-client.advertiseRoutes` (fill the real summer-place subnet); remove `openssh.openFirewall = true`. Then `nix flake update nix-vault` and deploy over LAN:
   `nixos-rebuild switch --flake .#island-pi --target-host root@<lan-ip>`
6. **Approve routes on controller** (headscale ≥0.26 syntax; verify with `--help`):
   ```bash
   sudo headscale nodes list-routes
   sudo headscale nodes approve-routes --identifier <node-id> --routes <subnet>
   ```
7. **Reboot the Pi once while you still have physical access** — verifies the lean deployed initrd (without the image's all-hardware profile) still mounts the SD root.

## Subnet router

`tailscale-client.advertiseRoutes` (option added to `modules/tailscale-client`) advertises the summer-place LAN and enables IP forwarding. Caveats:

- Flags apply at **registration only**. Changing routes later: `sudo tailscale set --advertise-routes=…` on the Pi.
- Routes need headscale-side approval (step 6 above).
- The summer-place subnet must not collide with the home LAN (`192.168.50.0/24`) — if both routers ship the same default subnet, renumber the summer one.

## Wake-on-LAN relay

`wake-island-stationary` (a one-line wrapper around `wakeonlan`) broadcasts a magic packet to island-stationary's MAC from `lib/default.nix`. Usage from anywhere on the tailnet:

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
