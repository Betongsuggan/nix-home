# Git Server

Minimal SSH-based git server. Creates a dedicated system user whose login shell is `git-shell`, so the existing sshd doubles as the git transport. No web UI, no extra daemon, no extra port.

## Usage

```nix
openssh.enable = true; # required - this module piggy-backs on sshd

git-server = {
  enable = true;
  repositories = [ "myrepo" ];
  authorizedKeys = [
    "ssh-ed25519 AAAA... user@workstation"
  ];
};
```

Clone with `git clone git@<host>:myrepo.git`.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the git server |
| user | string | "git" | System user that owns the repos and accepts SSH connections |
| dataDir | path | /var/lib/git | Directory holding bare repositories |
| repositories | list of string | [] | Repos to create; each `foo` becomes `<dataDir>/foo.git` |
| authorizedKeys | list of string | [] | SSH public keys allowed to access the git user |

## Notes

- Requires `openssh.enable = true` on the same host.
- The git user's shell is `git-shell`, which only permits git protocol commands. Interactive SSH (`ssh git@host`) is rejected.
- Repositories are bare (`git init --bare`) and created idempotently by a oneshot systemd unit (`git-server-init.service`) on activation. Existing repos are never modified, so you can safely add new entries to `repositories` later.
- No firewall changes are made by this module; port 22 must be reachable (e.g. via `openssh.openFirewall = true`).
