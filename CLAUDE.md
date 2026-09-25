# AI Rules

This file provides guidance to AI assistants when working with this repository

## General guidelines

This repository is handling different Nixos configurations for different machines. In this repository each physical machine
is referred to as a "host". Each host will have one or many users associated with it. The hosts are defined under the `hosts`
folder, with the name of the sub-folder defining the host name. Within each specific host, we will define both system wide
and user specific configuration. Most configuration for each host and user SHOULD be done by referencing one or many `modules`.

Hosts are registered in `lib/default.nix` (`hosts.<name>`, with an optional `system`, default `x86_64-linux`), and
`lib/mk-host.nix` builds each one from its folder by convention: `hosts/<name>/system.nix` is the host's NixOS config,
and every `hosts/<name>/user-<user>.nix` becomes that user's Home Manager config (Home Manager runs only as a NixOS
module). Shared wiring (module aggregators, overlays from `overlays/`, unfree policy, Home Manager settings) lives in
`mk-host.nix` once; hosts never repeat it. Upstream flake modules (lanzaboote, sops-nix, stylix, niri, ...) are imported
by the modules that use them.

The modules are defined in the `modules/` folder, one directory per module. A module's NixOS half lives in
`modules/<name>/nixos.nix` and its Home Manager half in `modules/<name>/home.nix` (either may be absent);
`modules/nixos.nix` and `modules/home.nix` import them. Every custom option lives under `my.<name>`, where `<name>` is
the module's directory (e.g. `my.window-manager.hyprland`, `my.file-manager`). When a feature is switched on per user in
Home Manager but needs system-side support, the `nixos.nix` half derives its enable from the users with
`inputs.self.lib.anyHomeUser config (u: u.my.<name>.enable)`, so the user only enables it in one place.

Roles live in `modules/profiles` (`my.profiles.{workstation,laptop,gaming-station}`, NixOS; the Home Manager `desktop`
profile follows `workstation`) and only set `mkDefault`s; `modules/common` is the always-on base. Prefer adding a default to
a profile or module over repeating a setting in several hosts.

Identity is registry-driven: hostnames (`hosts.<name>.hostName`), login accounts and git identity (`accounts`), who may SSH
where (`hosts.<host>.users.<user>.sshFrom` / `sshFromFleet`), SSH public keys (which also drive sops key placement) and
fleet constants (`domain`, `operator`, `tailnet`) all come from `lib/default.nix`. Never hardcode these in a host or module.

Window-manager keybinds are defined once in `my.window-manager.keybinds` (`modules/window-manager/home.nix`) and rendered by
each backend; add or change binds there, not in a backend. Multi-backend modules dispatch through an attrset of backends.

Verify every change: `nix flake check --no-build --all-systems` (all hosts plus `checks/backends.nix`), and for refactors
compare `scripts/baseline.sh` output before and after; a pure refactor must leave every drvPath unchanged. Never run
`nix flake lock --override-input nix-vault ...`: it writes the local path into `flake.lock`.

When we're creating new modules, it is important that TO AS BIG EXTENT POSSIBLE use the nix programming language to define it.

It is EXTREMELY important that you are critical to any existing and suggested solutions and give suggestions on what would be
a more idiomatic way of doing it in terms of usage pattern, Nixos idiomatics, Linux mindset.

## Specifications
Modules and hosts have `SPEC.md` files documenting their purposes, usage examples and necessary setup instructions. **Before working on a module or a host, you MUST ALWAYS read its spec. No exceptions:**
```
modules/{module-name}/SPEC.md
hosts/{host-name}/SPEC.md
```

When your changes affect observable behavior (configuration changes, required dependencies, purpose of the module), update the corresponding `SPEC.md` to reflect the changes. A PostToolUse hook will remind you when you modify the files in a module or hosts that has a spec.
