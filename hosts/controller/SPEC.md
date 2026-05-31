# Controller

Minimal Intel NUC host intended as a controller/server. The long-term goal is to run headless without a desktop environment.

## Key Features

- Niri tiling Wayland compositor with Vicinae launcher (wifi, bluetooth, monitor extensions)
- Alacritty terminal with Bash shell and Starship prompt
- Intel integrated graphics
- Audio via PipeWire
- NetworkManager with iwd backend
- OpenSSH server (port 22 reachable only on `tailscale0`)
- Minimal SSH git server (git-shell, single bare repo)
- Nginx reverse proxy with per-domain Let's Encrypt certs (HTTP-01), auto-renewing; currently `rydback.net` (404 stub + the tailnet bootstrap blob endpoint), `vpn.rydback.net` (proxies to headscale), `vault.rydback.net` (vaultwarden, tailnet-only)
- `home-network` module in `controller` mode: bundles the headscale coordinator at `vpn.rydback.net` (embedded DERP relay, declaratively provisioned users), the rotated YubiKey-encrypted preauth-blob endpoint, and tailscale client membership. See `modules/home-network/SPEC.md` for the full onboarding doctrine.
- Emulation server: Syncthing for save sync, Samba for read-only ROM/BIOS shares, data at `/var/lib/emulation`; Syncthing/Samba ports exposed only on `enp1s0` (LAN) and `tailscale0` (off-LAN)
- Restic backup source: pushes encrypted snapshots over SFTP-on-tailnet to `private-desktop` (on-site) and `island-stationary` (off-site, when onboarded). Paths: `/var/lib/{vaultwarden,headscale,emulation}` and `/var/lib/git/nix-vault.git`. Daily timer, `keep-daily 7 / keep-weekly 4 / keep-monthly 12` retention. See `modules/restic-backup/SPEC.md`.
- Sleep/suspend/hibernate fully disabled (systemd targets masked + logind ignores lid/power keys and idle)
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

## `nix-vault` enrollment role

Controller is the single source of truth for the `nix-vault.git` bare repository (the `nix-vault` flake input). Access is gated by `git-server.authorizedKeys` — a flat SSH pubkey allowlist (see `modules/git-server/SPEC.md`). The allowlist is derived automatically from `lib/default.nix` (`inputs.self.lib.allSshKeys`), plus the operator's YubiKey appended in this host's `system.nix` for bootstrap.

Port 22 is reachable only on `tailscale0` — `nix-vault.git` is cloned over the tailnet. New hosts that are not yet on the tailnet use the `home-network` bootstrap flow (see below) to join first, then proceed with the SSH-based clone.

The operator's YubiKey SSH key (FIDO `ed25519-sk` resident, touch-only) is authorized in **two** places on controller:

- `git-server.authorizedKeys` — to clone/push `nix-vault.git` from a fresh installer once it has joined the tailnet, *before* the new host's host SSH key has been added to `lib/default.nix`.
- `users.users.betongsuggan.openssh.authorizedKeys.keys` — to SSH in as `betongsuggan`, edit `nix-vault`, and `nixos-rebuild switch` controller.

One credential, all access. The YubiKey lives in the drawer until the next new-host enrollment.

For everyday admin from any tailnet peer, peers' SSH keys are pulled in via `home-network.authorizeSshFor.betongsuggan` (currently only `birgerrydback@bits`). No YubiKey touch required for routine work.

## Onboarding new hosts

The full doctrine — what each mode does, the exact installer-side commands, the post-install `mode = "onboarded"` flip, failure modes and recovery — lives in **`modules/home-network/SPEC.md`**. That is the single source of truth for fleet onboarding.

Quick summary of controller's role in the flow:

- Controller runs the rotated, age-encrypted preauth-blob endpoint at `https://rydback.net/.well-known/tailnet-bootstrap.age`. The blob refreshes every 15 minutes and is decryptable only with the operator's YubiKey.
- New hosts fetch the blob from their installer, decrypt with the YubiKey, and join the tailnet — no preexisting tailnet member required.
- Once on the tailnet, the new host clones `nix-vault.git` from `controller` over SSH (YubiKey-authed), registers its age recipient in `nix-vault/.sops.yaml`, populates its own `secrets/<host>.yaml` (with the host-specific long-lived preauth key generated via `sudo headscale preauthkeys create -u birger --reusable -e 8760h`), and `nixos-install`s.

To later allow a host to clone/pull `nix-vault` itself for unattended `nix flake update`, add that host's `/etc/ssh/ssh_host_ed25519_key.pub` under `hosts.<host>.ssh.users` in `lib/default.nix`, push, and rebuild controller.
