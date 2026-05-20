# Tailscale Client

Joins a host to a headscale-managed tailnet using a preauth key supplied via a file (typically a sops-decrypted secret).

## Usage

```nix
sops.secrets."headscale-preauthkey" = {
  key = "services/headscale-preauthkey";
  owner = "root";
  mode = "0400";
};

tailscale-client = {
  enable = true;
  loginServer = "https://headscale.example.com";
  authKeyFile = config.sops.secrets."headscale-preauthkey".path;
  extraUpFlags = [ "--accept-routes" ];
};
```

On first boot after enabling, tailscaled reads the preauth key from `authKeyFile`, registers the node against `loginServer`, and brings the interface up.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the tailscale daemon and register against headscale |
| loginServer | string | (required) | URL of the headscale control server, e.g. `https://headscale.example.com` |
| authKeyFile | path | (required) | File containing the preauth key (one line, no trailing newline issues) |
| extraUpFlags | list of string | [ ] | Extra flags passed to `tailscale up` on first registration |

## Notes

- `services.tailscale.authKeyFile` is consumed only when the node has no existing tailscale state. After successful registration, the key is no longer used; rotating it requires re-registering the node.
- Use a long-lived (`-e 8760h`) `--reusable` preauth key so rebuilds before re-registration don't break things.
- The preauth key is generated on the headscale server with `sudo headscale preauthkeys create -u <user> --reusable -e 8760h`, then encrypted into the `nix-vault` flake.
- This module does not open the firewall. Tailscale handles its own UDP socket and works fine through a default-deny firewall on outbound connections.
