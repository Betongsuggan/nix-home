# Fleet Status

Every host's status on one screen. Each host serves a small JSON status document on the tailnet. An admin's launcher shows all hosts with their state, and offers SSH, wake, a rebuild check and details for each.

## Usage

Nothing to set: the status service is on wherever tailscale is, and the dashboard is on for admins (`my.common.admins`) with the desktop profile. Open it with **Mod+G**, or run `fleet-dashboard`.

```nix
my.fleet-status.enable = false;             # NixOS: don't serve status
my.fleet-status.dashboard.enable = true;    # Home Manager: a non-admin user
```

## Options

| Option | Half | Type | Default | Description |
|--------|------|------|---------|-------------|
| enable | NixOS | bool | `services.tailscale.enable` | Serve this host's status on `lib.tailnet.statusPort` (9099), tailnet interface only |
| dashboard.enable | Home Manager | bool | admin with the desktop profile | Install `fleet-dashboard` and bind Mod+G |
| dashboard.flake | Home Manager | str | `~/nix-home` | Checkout the rebuild check evaluates |
| dashboard.package | Home Manager | package (read-only) | | The dashboard command |

## Behaviour

- **Status service**: a socket-activated systemd service (`fleet-status.socket`, `Accept=yes`, `DynamicUser`), so nothing runs between requests. The firewall opens its port on the tailscale interface only. Each request returns:
  - `battery`: capacity and state
  - `disk`: `/` used percent and free bytes
  - `uptime`
  - `backups`: each restic job's last finish and result
  - `system`: the running system
  - `rebootPending`: the running system differs from the booted one
  - `rebuilt`: when the system profile last changed
- **Dashboard rows**: the registry's hosts, fetched in parallel (2 s timeout). A host that doesn't answer shows tailscale's view instead: asleep since when, online but without a status service, or not on the tailnet.
- **Actions**, derived from the registry for this user on this host:
  - **SSH** where `sshFrom` allows it; it opens a terminal on the `ssh <host>` alias from `modules/ssh`
  - **Wake** where the host has a `wol` relay this user can reach (`ssh <relay> wake-<host>`)
  - **Check if a rebuild is needed**: evaluates the host's toplevel from `dashboard.flake` with the locked inputs, and compares it with the system it runs
  - **Details**
  - **Copy address**
