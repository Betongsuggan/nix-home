# Common

Baseline imported by every host (no enable switch).

## Usage

Nothing to enable. The one option:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| my.common.accounts | list of str | set by `lib/mk-host.nix` | Login accounts on this host: registry users that exist in `lib.accounts`, plus every Home Manager user |
| my.common.admins | list of str (read-only) | accounts with `admin = true` | Modules add their groups to these (networkmanager, docker, uinput/input) |
| my.common.systemd-boot | bool | true | Boot via systemd-boot on UEFI (generation limit 10, may touch EFI variables). island-pi turns it off for extlinux. |

## What it sets

- One `users.users.<name>` per account, with its description from `lib.accounts`; admins get `wheel` and `video`. Hosts only add what is specific to them (e.g. `authorizedKeys`, an extra group).

- Base host defaults (all `mkDefault`): timezone Europe/Stockholm, colemak console keymap, redistributable firmware, a 200 MB journal cap, a 1 s boot-menu timeout, `/tmp` emptied at every boot (it stays on disk).

- Nix: flakes and `nix-command`; weekly garbage collection of generations older than 14 days and weekly store deduplication (`nix.optimise`), both with a 45 min random delay and at idle CPU/IO priority so a missed run caught up after boot doesn't compete with the session; parallel builds (the laptop profile caps `max-jobs` at 2); and the nix-community / walker / niri Cachix substituters. No `keep-outputs`/`keep-derivations`, so GC actually reclaims build dependencies.
- aarch64 emulation via binfmt on x86_64 hosts, so any fleet machine can build and deploy island-pi.
- A few base packages (git, vim, wget, curl, sshfs) and `programs.dconf` (needed for Home Manager's GTK dark-mode settings to reach GTK apps).
- sshd defaults for any host that enables `services.openssh`: key-only authentication, no root login, and no global firewall opening (all `mkDefault`, so a host can override them).
- Controller's SSH host key in `programs.ssh.knownHosts`, from `lib.hosts.controller.ssh.host`, so fetching `nix-vault` never hits a trust-on-first-use prompt.
