# SSH (client)

Home Manager SSH client setup derived from the registry in `lib/default.nix`. Enabled for every user by the base Home Manager profile.

## What it sets

- A `Host <name> <fqdn>` block (e.g. `desktop desktop.ts.rydback.net`) for every fleet account this user may log into (`lib.sshTargetsOf`, the reverse of `lib.sshFrom`). Each block logs in as the target user, with `IdentitiesOnly` and the user's identities, so `ssh <host>` works without a user name. The fleet dashboard's SSH action (Mod+G, `modules/fleet-status`) opens the same aliases.
- Identities: `hosts.<host>.users.<user>.sshIdentities` (key file names under `~/.ssh`), defaulting to all of the user's registry keys.
- `~/.ssh/<key>.pub` for each of the user's registry keys. The private halves are placed by the `sops` module.
- `ssh-agent` with `SSH_AUTH_SOCK` in the systemd user environment.

Host keys of every registry host are pinned system-wide by `modules/common`, so a first connection doesn't prompt.

## The fleet SSH mesh

By default every admin identity (`accounts.<user>.admin`, with registry keys on its host; `lib.fleetPeers`) may log into every admin account on every other host that runs fleet sshd (has `ssh.host`). The server side (`authorized_keys`) is written by `modules/home-network`. Service users (e.g. `restic`) and non-admins are not part of it. A user with no registry key on a host (e.g. island-pi) can be logged into but can't start sessions from there.

## Usage

```nix
my.ssh.enable = true; # default via modules/profiles/home.nix
```

Non-fleet hosts (e.g. GitHub) are added per user with plain `programs.ssh.settings`.

## Registry fields

| Field (under `hosts.<host>.users.<user>`) | Meaning |
|---|---|
| `ssh.<key>` | Public key; `<key>` is the file name under `~/.ssh` and the key name in the vault (`users/<user>/ssh/<key>`) |
| `sshIdentities` | Which of the user's keys (or other files in `~/.ssh`) to offer to the fleet |
| `sshFrom` | `[ { host; user; } ]`: overrides the mesh with exactly these identities (`[ ]` to opt out) |
