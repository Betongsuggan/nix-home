# Common

Baseline imported by every host (no enable switch).

## What it sets

- Nix: flakes and `nix-command`, weekly garbage collection of generations older than 14 days, store auto-optimisation, parallel builds, and the nix-community / walker / niri Cachix substituters.
- aarch64 emulation via binfmt on x86_64 hosts, so any fleet machine can build and deploy island-pi.
- A few base packages (git, vim, wget, curl, sshfs) and `programs.dconf` (needed for Home Manager's GTK dark-mode settings to reach GTK apps).
- Controller's SSH host key in `programs.ssh.knownHosts`, from `lib.hosts.controller.ssh.host`, so fetching `nix-vault` never hits a trust-on-first-use prompt.
