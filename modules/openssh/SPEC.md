# openssh

Thin wrapper around `services.openssh` with safe defaults: firewall closed, password authentication disabled, root login disabled. Enabling this module guarantees `/etc/ssh/ssh_host_ed25519_key` is generated at activation, which is also required for sops-nix to use the host's SSH host key as its age decryption identity. The `sops-secrets` module enables `openssh.enable = true` implicitly for that reason.

## Usage

```nix
# In hosts/<host>/system.nix
openssh = {
  enable = true;
  openFirewall = true;      # only if you actually want to accept connections
};
```

For a host that only needs sshd as a means to generate host keys (e.g. so sops-nix has something to decrypt with), you can leave everything at defaults — `sops-secrets.enable = true` flips `openssh.enable` on, the firewall stays closed, and sshd is effectively unreachable.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable sshd. |
| openFirewall | bool | false | Open port 22 in the firewall. |
| permitRootLogin | enum | "no" | Value of sshd's `PermitRootLogin`. |
| passwordAuthentication | bool | false | Allow password logins. |

## Notes

- `/etc/ssh/ssh_host_ed25519_key` is created on activation and lives outside `/nix/store`, so it persists across rebuilds and is stable enough to serve as the host's long-lived sops-nix decryption identity.
- For accepting connections from other hosts, set `openFirewall = true` and declare `users.users.<name>.openssh.authorizedKeys.keys` (or `.keyFiles`) — those upstream options aren't re-exposed here since they're already concise.
