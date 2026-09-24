# Common

Baseline imported by every host (no enable switch).

## Usage

Nothing to enable. The one option:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| my.common.systemd-boot | bool | true | Boot via systemd-boot on UEFI (generation limit 10, may touch EFI variables). island-pi turns it off for extlinux. |

## What it sets

- Base host defaults (all `mkDefault`): timezone Europe/Stockholm, colemak console keymap, redistributable firmware.

- Nix: flakes and `nix-command`, weekly garbage collection of generations older than 14 days, store auto-optimisation, parallel builds, and the nix-community / walker / niri Cachix substituters.
- aarch64 emulation via binfmt on x86_64 hosts, so any fleet machine can build and deploy island-pi.
- A few base packages (git, vim, wget, curl, sshfs) and `programs.dconf` (needed for Home Manager's GTK dark-mode settings to reach GTK apps).
- sshd defaults for any host that enables `services.openssh`: key-only authentication, no root login, and no global firewall opening (all `mkDefault`, so a host can override them).
- Controller's SSH host key in `programs.ssh.knownHosts`, from `lib.hosts.controller.ssh.host`, so fetching `nix-vault` never hits a trust-on-first-use prompt.
