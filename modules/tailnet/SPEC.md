# Tailnet

Membership in the headscale tailnet for a host: tailscale client, SSH on `tailscale0` only, and peer SSH keys from the lib registry. Usually enabled indirectly by `my.home-network` (mode `onboarded`) rather than set on a host directly.

## Usage

```nix
my.tailnet.enable = true;

# Who may log in is declared in the registry, next to the account:
#   hosts.desktop.users.betongsuggan.sshFrom = [ { host = "bits"; user = "birgerrydback"; } ];
#   hosts.controller.users.betongsuggan.sshFromFleet = true;   # every fleet identity
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Join the tailnet with the bundled SSH server/client defaults |
| authorizeSshFor | attrs of list of `{ host, user }` | the host's accounts' `sshFrom` / `sshFromFleet` from `lib.hosts` | Per local user, the peers whose keys under `lib.hosts.<host>.users.<user>.ssh.*` are added to `authorized_keys`. Normally left at the default. |

## Behaviour

- Enables `my.tailscale-client` against `https://vpn.rydback.net` with `--accept-routes --accept-dns`.
- Enables `services.openssh` with the global firewall closed (the key-only defaults come from `modules/common`); port 22 is opened on `tailscale0` only.
- Lets root (nix-daemon) fetch the `nix-vault` input from `git@controller` over the tailnet with the host SSH key (`Match localuser root user git`), without affecting user SSH configs.
- With `my.sops.enable`, the tailscale auth key comes from the sops secret `services/headscale-preauthkey`.
