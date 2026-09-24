# Tailnet

Membership in the headscale tailnet for a host: tailscale client, SSH on `tailscale0` only, and peer SSH keys from the lib registry. Usually enabled indirectly by `my.home-network` (mode `onboarded`) rather than set on a host directly.

## Usage

```nix
my.tailnet = {
  enable = true;
  # Local user -> fleet identities whose SSH keys may log in as that user
  authorizeSshFor.betongsuggan = [
    { host = "bits"; user = "birgerrydback"; }
  ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Join the tailnet with the bundled SSH server/client defaults |
| authorizeSshFor | attrs of list of `{ host, user }` | `{ }` | Per local user, the peers whose keys under `lib.hosts.<host>.users.<user>.ssh.*` are added to `authorized_keys` |

## Behaviour

- Enables `my.tailscale-client` against `https://vpn.rydback.net` with `--accept-routes --accept-dns`.
- Enables `my.openssh` with the global firewall closed; port 22 is opened on `tailscale0` only.
- Lets root (nix-daemon) fetch the `nix-vault` input from `git@controller` over the tailnet with the host SSH key (`Match localuser root user git`), without affecting user SSH configs.
- With `my.sops.enable`, the tailscale auth key comes from the sops secret `services/headscale-preauthkey`.
