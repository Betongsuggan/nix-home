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
- **Dashboard rows**: the registry's hosts, with ` · power on 48 W` / ` · power off` appended when the host has a plug that answered (fetched in parallel with the statuses, so a powered-off host still shows it). Those tailscale reports online are fetched in parallel (2 s timeout); asleep or absent ones aren't asked, so they don't hold the menu up for the timeout (all are asked when `tailscale status` fails). A host without a status shows tailscale's view instead: asleep since when, online but without a status service, or not on the tailnet.
- **Actions**, derived from the registry for this user on this host:
  - **SSH** where `sshFrom` allows it; it opens a terminal on the `ssh <host>` alias from `modules/ssh`
  - **Wake** where the host has a `wol` relay this user can reach (`ssh <relay> wake-<host>`)
  - **Power on** / **Power off** where the host is powered through a smart plug (registry `hosts.<host>.plug`, [[shelly-plug]]): `plug-<name> on|off` straight from this host. Off asks "Cut power to <host>?" first, and is refused for the host the dashboard runs on. No toggle: it would race a stale row. A plug that is off gives the NIC no standby power, so Wake only works after Power on; whether Power on alone boots the host is the BIOS's "restore on AC loss" setting.
  - **Check if a rebuild is needed**: evaluates the host's toplevel from `dashboard.flake` with the locked inputs, and compares it with the system it runs
  - **Details**
  - **Copy address**
