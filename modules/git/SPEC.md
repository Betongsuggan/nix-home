# Git

Configures git with user identity, diff-so-fancy pager, SSH-based GitHub URLs, common aliases, and libsecret credential storage.

## Usage

```nix
git = {
  enable = true;
  userName = "Your Name";
  userEmail = "you@example.com";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable git |
| userName | str | "Birger Rydback" | Name for git |
| userEmail | str | "birger@humla.io" | Email for git |

## Notes

- Installs diff-so-fancy and uses it as the default pager.
- Rewrites `https://github.com` URLs to `ssh://git@github.com`.
- Enables `push.autoSetupRemote`.
- Uses `git-credential-libsecret` for credential storage.
- Includes aliases: `f` (fetch), `s` (status), `d` (diff), `co` (checkout), `br` (new branch), `cm` (commit -m), `ca` (amend), `aa` (add all), `p` (push), `fp` (force-with-lease push), `tree` (graph log), and more.
