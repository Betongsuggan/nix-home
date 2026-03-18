# AI Rules

This file provider guidance to AI assistants when working with this repository

## General guidelines

This repository is handling different Nixos configurations for different machines. In this repository each physical machine
is referred to as a "host". Each host will have one or many users associated with it. The hosts are defined under the `hosts`
folder, with the name of the sub-folder defining the host name. Within each specific host, we will define both system wide
and user specific configuration. Most configuration for each host and user SHOULD be done by referencing one or many `modules`.

The modules are defined in the `modules/` folder. System modules configure host-wide settings (graphics, cpu, bluetooth,
networking, etc.) and are aggregated via `modules/system.nix`. User modules configure per-user settings (window managers,
browsers, development setups, etc.) and are aggregated via `modules/user.nix`. Some modules (file-manager, emulation-server,
game-streaming) have both a `system.nix` and `user.nix` inside a single directory, with auto-enable logic so users only
need to enable the module in one place.

When we're creating new modules, it is importand that TO AS BIG EXTENT POSSIBLE use the nix programming language to define it.

It is EXTREMELY important that you are critical to any existing and suggested solutions and give suggestions on what would be
a more idiomatic way of doing it in terms of usage pattern, Nixos idiomatics, Linux mindset.

## Specifications
Modules and hosts have `SPEC.md` files documenting their purposes, usage examples and necessary setup instructions. **Before working on a module or a host, you MUST ALWAYS read its spec. No exceptions:**
```
modules/{module-name}/SPEC.md
hosts/{host-name}/SPEC.md
```

When your changes affect observable behavior (configuration changes, required dependencies, purpose of the module), update the corresponding `SPEC.md` to reflect the changes. A PostToolUse hook will remind you when you modify the files in a module or hosts that has a spec.
