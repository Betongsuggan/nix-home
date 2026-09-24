# SSH (client)

Home Manager SSH client setup derived from the registry in `lib/default.nix`. Enabled for every user by the base Home Manager profile.

## What it sets

- A `Host <name> <name>.ts.rydback.net` block for every fleet account this user may log into, i.e. every target whose `sshFrom` (or `sshFromFleet`) includes this user on this host (`lib.sshTargetsOf`). Each block logs in as the target user, with `IdentitiesOnly` and the user's identities.
- Identities: `hosts.<host>.users.<user>.sshIdentities` (key file names under `~/.ssh`), defaulting to all of the user's registry keys.
- `~/.ssh/<key>.pub` for each of the user's registry keys. The private halves are placed by the `sops` module.
- `ssh-agent` with `SSH_AUTH_SOCK` in the systemd user environment.

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
| `sshFrom` | `[ { host; user; } ]` fleet identities allowed to log in to this account |
| `sshFromFleet` | `true` to allow every fleet identity (controller) |
