# Onboarding: nix-home

This flake configures a small fleet of machines and their users: NixOS for each host, Home Manager for each user (as a NixOS module), and a shared registry that ties them together. Read `README.md` for the overview; this guide is the practical path from zero to making a change.

## 1. What you need

- **Nix with flakes** (`nix-command flakes`; every host already has them).
- **Access to `nix-vault`**, the private flake input holding sops-encrypted secrets. It is served by `controller` over the headscale tailnet (`git@controller.ts.rydback.net`). Off the tailnet, keep a local clone and pass `--override-input nix-vault path:$HOME/nix-vault` to `nix eval`/`build`/`flake check`.
- **The operator YubiKey** only for enrolling a new host or editing secrets (`sops`, `age-plugin-yubikey`).

## 2. First hour

```bash
git clone git@github.com:Betongsuggan/nix-home.git && cd nix-home
nix flake check --no-build --all-systems   # evaluates all 7 hosts + every backend (~10 min)
scripts/baseline.sh                        # one drvPath per host
```

Then read, in this order:

1. `README.md` — hosts, layout, how the pieces fit.
2. `CLAUDE.md` — the working rules (also what AI assistants follow).
3. `lib/default.nix` — the registry: hosts, accounts, SSH relations, fleet constants.
4. `lib/mk-host.nix` — how a host folder becomes a `nixosConfiguration`.
5. The `SPEC.md` of the host you care about (`hosts/<host>/SPEC.md`) and of any module before touching it.

## 3. How the repo is organised

| Path | What lives there |
|---|---|
| `lib/default.nix` | The registry. Everything other machines need to know about a host or person: hostnames, per-user SSH keys, who may SSH where (`sshFrom`), Syncthing IDs, `accounts` (description, admin, git identity), `domain`, `operator`, `tailnet`. |
| `lib/mk-host.nix` | Builds each registry entry from `hosts/<name>/`: `system.nix` is the NixOS config, each `user-<user>.nix` a Home Manager user. |
| `hosts/<name>/` | Per-machine config: a profile, hardware, and what is genuinely unique to it. |
| `modules/<name>/` | `nixos.nix` and/or `home.nix`, auto-imported; options under `my.<name>`. |
| `modules/profiles/` | Roles (`workstation`, `laptop`, `gaming-station`) that set `mkDefault`s. |
| `modules/common/` | The always-on base for every host. |
| `overlays/` | Packages from other flakes and local fixes. |
| `checks/backends.nix` | Evaluates every unused backend so alternatives cannot rot. |
| `docs/` | Planning notes (AI setup, de-googling). |

Rules of thumb:

- **Configure things once.** If two hosts need the same setting, it belongs in a module or profile default, not in both host files. Identity (hostnames, accounts, SSH access, domains) always comes from `lib/default.nix`.
- **A user feature is enabled in one place.** If it needs system support, the module's `nixos.nix` derives it from the users (`inputs.self.lib.anyHomeUser`).
- **Backends are interchangeable.** Window managers, launchers, terminals, shells, notification daemons and file managers sit behind one interface. Keybinds are defined once in `my.window-manager.keybinds` (`modules/window-manager/home.nix`) and rendered for every compositor.
- **One color scheme per user.** `my.theming.scheme` (`gruvbox` or `kanagawa`, defined in `modules/theming/schemes.nix`) drives everything: stylix themes apps with the scheme's canonical base16 file, the editor loads the scheme's Neovim colorscheme, and modules stylix can't reach (waybar, niri, Hyprland borders) read `my.theming.colors`, which default to the scheme's terminal palette.
- **The editor lives in its own repository.** nvim is the `nvim` flake input (`github:Betongsuggan/nvim`, a nixvim config); `modules/editor` (`my.editor`) builds it per user with `.extend`: languages follow `my.development` (Nix for admin accounts), colors follow the scheme, and nixd completes this host's NixOS/HM options. Editor behavior (plugins, keymaps, language servers) is changed in that repository, not here.

## 4. Day-to-day workflow

```bash
# edit, then:
nix fmt
nix flake check --no-build --all-systems
sudo nixos-rebuild test --flake .#<host>     # try it; reboot undoes it
sudo nixos-rebuild switch --flake .#<host>   # keep it
```

- Home Manager has no separate `home-manager switch`; `nixos-rebuild` applies both.
- `nvd diff /run/current-system result` (after `nixos-rebuild build`) shows what a rebuild will change.
- **Refactors must be provable:** run `scripts/baseline.sh > before` on the old commit and `> after` on the new one; a pure refactor leaves every drvPath identical. If a hash changes, find out why before committing.
- Update the `SPEC.md` of every module or host whose behaviour you change (a hook reminds you).
- One focused commit per change, with a message explaining why.

## 5. Common tasks

**Change a setting on one machine.** Edit `hosts/<host>/system.nix` or `user-<user>.nix` using the `my.*` options (see the module's `SPEC.md`). If you find yourself copying it to a second host, move it into a module or profile instead.

**Add a module.** Create `modules/<name>/home.nix` and/or `nixos.nix` with options under `my.<name>`, plus a `SPEC.md`. It is picked up automatically. If it has several backends, dispatch through an attrset of backends and add the variants to `checks/backends.nix`.

**Give an account SSH access to another.** Add `{ host; user; }` to the target account's `sshFrom` in `lib/default.nix`. Authorized keys on the target, the `Host` block on the source, and key placement follow; rebuild both machines.

**Add a user to a host.** Add the person to `lib.accounts` if new, then create `hosts/<host>/user-<name>.nix`. The account, groups and git identity come from the registry.

**Change the colors.** Set `my.theming.scheme` in the user's file. A new scheme is one entry in `modules/theming/schemes.nix` (its base16 file from `pkgs.base16-schemes`, its terminal palette, its Neovim colorscheme — which must exist in the nvim flake's `theme.colorscheme`).

**Change the editor.** Language support per user: `my.editor.languages.<lang>` (defaults from `my.development`). Anything inside the editor: edit `~/Development/nvim` (every keymap in `config/keymaps.nix`, every language in `config/languages.nix`), run its `nix flake check`, push, then `nix flake update nvim` here. To try an unpushed editor change first: `nix build --no-write-lock-file --override-input nvim path:$HOME/Development/nvim …` (never `nix flake lock` with overrides).

**Fingerprint and Bitwarden on a laptop.** Set `my.fingerprint` in the host's `system.nix` (driver per `modules/fingerprint/SPEC.md`), rebuild, then run `fprintd-enroll`. Login (ReGreet), hyprlock, sudo and polkit prompts all take the finger or the password. Bitwarden (on for admins) unlocks with it after the one-time app and extension settings in `modules/password-manager/SPEC.md`.

**Add a host.** Register it in `lib/default.nix`, create `hosts/<name>/system.nix` (choose a profile), and follow `modules/home-network/SPEC.md` to join the tailnet and enrol it in `nix-vault`.

## 6. Gotchas

- **Never run `nix flake lock --override-input nix-vault ...`.** It writes your local path into `flake.lock`. If you relock, restore the `nix-vault` node from `HEAD` afterwards.
- The locked `nix-vault` revision is what real rebuilds use; `nix flake update nix-vault` to pick up new secrets.
- `nixos-rebuild --flake .#bits` with no trailing punctuation — `.#bits.` looks for a host literally named `bits.`.
- Unused alternatives (sway, i3, waybar, polybar, …) are kept on purpose; `nix flake check` is what keeps them working.
- A running nvim keeps the build it started with; reopen it after a rebuild to get a new editor.

## 7. Where to ask

The per-host and per-module `SPEC.md` files are the source of truth for why things are the way they are; `git log -- <path>` explains the history. Anything still unclear: ask Birger.
