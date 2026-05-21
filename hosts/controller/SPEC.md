# Controller

Minimal Intel NUC host intended as a controller/server. The long-term goal is to run headless without a desktop environment.

## Key Features

- Niri tiling Wayland compositor with Vicinae launcher (wifi, bluetooth, monitor extensions)
- Alacritty terminal with Bash shell and Starship prompt
- Intel integrated graphics
- Audio via PipeWire
- NetworkManager with iwd backend
- OpenSSH server (firewall port open)
- Minimal SSH git server (git-shell, single bare repo)
- Nginx reverse proxy with Let's Encrypt TLS
- Headscale Tailscale coordination server with embedded DERP relay (declaratively provisioned users)
- Tailscale client joined to the local headscale tailnet (`--accept-routes`)
- Emulation server: Syncthing for save sync, Samba for read-only ROM/BIOS shares, data at `/var/lib/emulation`; Syncthing/Samba ports exposed only on `enp1s0` (LAN) and `tailscale0` (off-LAN)
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

Controller is the single source of truth for the `nix-vault.git` bare repository (the `nix-vault` flake input). Access is gated by `git-server.authorizedKeys` — a flat SSH pubkey allowlist (see `modules/git-server/SPEC.md`). The allowlist is derived automatically from `nix-vault`'s `keys.nix` (`lib.collect lib.isString inputs.nix-vault.keys.hosts`), plus the operator's YubiKey appended in this host's `system.nix` for bootstrap.

The operator's YubiKey SSH key (FIDO `ed25519-sk` resident, touch-only) is authorized in **two** places on controller:

- `git-server.authorizedKeys` — to clone/push `nix-vault.git` from a fresh installer *before* the new host's key has been added to `keys.nix`.
- `users.users.betongsuggan.openssh.authorizedKeys.keys` — to SSH in as `betongsuggan`, edit `nix-vault/keys.nix` and `nix-vault/.sops.yaml`, and `nixos-rebuild switch` controller.

One credential, all access. The YubiKey lives in the drawer until the next new-host enrollment.

For everyday admin from the operator's `bits` laptop, `birgerrydback@bits`'s per-host SSH key (sourced from `inputs.nix-vault.keys.hosts.bits.users.birgerrydback.bits`) is also authorized on `betongsuggan` — no YubiKey touch required for routine work.

### Per-new-host enrollment runbook

With the YubiKey inserted in either the new host or the operator's workstation:

1. Boot the new host's installer. Insert YubiKey. Materialize the resident FIDO keypair:
   ```
   ssh-keygen -K
   eval "$(ssh-agent)"
   ssh-add ~/.ssh/id_ed25519_sk_bootstrap
   ssh-keyscan -t ed25519 192.168.50.50 >> ~/.ssh/known_hosts
   ```
2. Clone `nix-home` (public). Clone `nix-vault` (YubiKey-authed):
   ```
   git clone git@192.168.50.50:nix-vault.git
   ```
3. Make sure the new host has a `hosts/<new-host>/` entry in `flake.nix`.
4. Generate the new host's `/etc/ssh/ssh_host_ed25519_key` (or boot, generate, then proceed — see sops two-pass note in `modules/sops/SPEC.md`). Convert pubkey to age recipient with `ssh-to-age`. Add the recipient to `nix-vault/.sops.yaml`; `sops updatekeys` affected files. Commit, push to controller's bare (YubiKey-authed).
5. `nixos-install --flake .#<new-host> --override-input nix-vault path:/path/to/nix-vault` (or rely on the flake's locked input, if the URL has been migrated to git+ssh:// and the host's key is registered).

To later allow a host to clone/pull `nix-vault` itself (e.g. for unattended `nix flake update`), add that host's `/etc/ssh/ssh_host_ed25519_key.pub` under `hosts.<host>.users` (or a dedicated host slot) in `nix-vault/keys.nix`, push, and rebuild controller. SSH client config is then a per-invocation concern (`ssh -i /etc/ssh/ssh_host_ed25519_key git@controller …` or per-user `~/.ssh/config`); there's no system module enforcing it.
