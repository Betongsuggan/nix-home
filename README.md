# nix-home

One flake for every machine I run: NixOS hosts, their users' Home Manager configuration, and the small fleet registry that ties them together (tailnet names, SSH keys, Syncthing IDs, accounts).

## Hosts

| Host | Role |
|---|---|
| `bits` | Work laptop (AMD, Hyprland) |
| `private-laptop` | Personal convertible laptop (Intel, niri) |
| `desktop` | Gaming and AI workstation, couch-gaming `gamer` session, Sunshine streaming |
| `island-stationary` | Gaming machine at the summer place |
| `controller` | Home server: headscale, reverse proxy, Vaultwarden, Nextcloud, git (nix-vault), backups |
| `island-pi` | Raspberry Pi 3 wake-on-LAN relay at the summer place (aarch64) |
| `mail` | Hetzner VM for self-hosted mail (scaffold) |

Each host's `SPEC.md` (`hosts/<host>/SPEC.md`) describes it in detail.

## Usage

```bash
sudo nixos-rebuild switch --flake .#<host>    # system and Home Manager together
nix fmt                                       # format (nixfmt)
nix flake check --no-build --all-systems      # evaluate every host and backend
scripts/baseline.sh > /tmp/before             # per-host drvPaths, to prove a refactor changed nothing
```

Home Manager runs only as a NixOS module; there is no separate `home-manager switch`. Secrets come from the private `nix-vault` flake input (sops-nix), fetched from controller over the tailnet; off the tailnet, evaluate with `--override-input nix-vault path:~/nix-vault`.

## How it fits together

- **Registry** (`lib/default.nix`): hosts (`system`, `hostName`, per-user SSH keys, who may SSH in via `sshFrom`, Syncthing IDs), `accounts` (description, admin flag, git identity), the operator, and tailnet constants. Everything that other hosts need to know about a host lives here, once.
- **Hosts** (`hosts/<name>/`): `lib/mk-host.nix` builds every registry entry from its folder: `system.nix` is the NixOS config and each `user-<user>.nix` becomes that user's Home Manager config. Hosts mostly pick a profile and state their hardware.
- **Modules** (`modules/<name>/`): `nixos.nix` and/or `home.nix`, discovered automatically. Every option lives under `my.<name>`. A feature a user switches on in Home Manager derives its system half from the users (`lib.anyHomeUser`), so it is enabled in one place.
- **Profiles** (`modules/profiles`): `workstation`, `laptop` and `gaming-station` set defaults (`mkDefault`) for a whole role; `modules/common` is the always-on base (nix settings, timezone, keymap, boot, accounts, sshd defaults).
- **Alternatives**: window managers (Hyprland, niri, sway, i3), launchers, terminals, shells, notification daemons and file managers are backends behind one interface; one keymap (`my.window-manager.keybinds`) is rendered for every compositor, and `checks/backends.nix` evaluates every backend so unused ones cannot rot.
- **Overlays** (`overlays/`): packages from other flakes and a few local fixes.

## Adding things

- **A module**: create `modules/<name>/{nixos,home}.nix` with options under `my.<name>`, and a `SPEC.md`.
- **A host**: add it to `lib/default.nix` and create `hosts/<name>/system.nix` (plus `user-*.nix`); joining the tailnet is walked through in `modules/home-network/SPEC.md`.
- **SSH access**: add the target account's `sshFrom` in the registry; the authorized keys, client `Host` blocks and key placement follow.
