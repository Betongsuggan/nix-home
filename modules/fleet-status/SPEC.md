# Fleet Status

Every host's status on one screen. Each host serves a small JSON status document on the tailnet, and tells its WoL relay before it suspends or shuts down, so an absent host reads as *asleep*, *shut down* or *no power* (its smart plug, [[shelly-plug]]) rather than tailscale's bare *offline*. An admin's launcher shows all hosts with their state, and offers SSH, wake, power, a rebuild check and details for each.

## Usage

Nothing to set: the status service is on wherever tailscale is, and the dashboard is on for admins (`my.common.admins`) with the desktop profile. Open it with **Mod+G**, or run `fleet-dashboard`.

```nix
my.fleet-status.enable = false;             # NixOS: don't serve status
my.fleet-status.dashboard.enable = true;    # Home Manager: a non-admin user
```

## Options

| Option | Half | Type | Default | Description |
|--------|------|------|---------|-------------|
| enable | NixOS | bool | `services.tailscale.enable` | Serve this host's status on `lib.tailnet.statusPort` (9099), tailnet interface only, and accept peers' announcements |
| announceTo | NixOS | null or host | the registry's `hosts.<host>.wol.relay` | Host told before suspend/shutdown and after resume (`fleet-announce`). Null: announce nothing. |
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
  - `peers`: what other hosts last announced to this one, `{ <host>: { state: suspend|shutdown|resume, at } }`
- **Announcements** (`announceTo`): `fleet-announce suspend` runs before `sleep.target` (`fleet-announce-sleep.service`), `fleet-announce shutdown` is the `ExecStop` of a unit ordered after tailscaled so it runs while the tailnet is still up (reboots announce it too; the next boot's live status wins), `fleet-announce resume` runs from `powerManagement.resumeCommands`. Each is one `POST /state` with `{"state": …}` to the relay's status port, by tailnet IP (no DNS on the way down), 3 s timeout so a missing relay never delays a suspend. The responder identifies the sender by `REMOTE_ADDR` (set by systemd for `Accept=yes`) against the registry's tailnet IPs: anyone else gets 403, anything but the three states 400. Announcements live in `/var/lib/fleet-status/peers/<host>.json` on the relay.
- **Dashboard rows**: the registry's hosts. Those tailscale reports online are fetched in parallel (2 s timeout); asleep or absent ones aren't asked, so they don't hold the menu up for the timeout (all are asked when `tailscale status` fails). Plugs are fetched alongside. A host that answers shows its status (plus ` · power 78 W` when it has a plug). One that doesn't is resolved in this order:
  | Row | Meaning |
  |---|---|
  | `⏻ desktop · no power` | its plug's relay is open |
  | `○ desktop · asleep since 3h · 19 W` | it announced `suspend` to its relay |
  | `⏼ desktop · shut down since 2d · 19 W` | it announced `shutdown` |
  | `? desktop · unreachable · seen 2d ago · 19 W` | powered, no announcement: crashed, or lost power while on |
  | `○ laptop · offline · seen 2d ago` | no plug, no announcement: tailscale's view is all there is |
  | `◐ … online, no status` / `✗ … not on the tailnet` | as before |
- **Actions**, derived from the registry for this user on this host:
  - **SSH** where `sshFrom` allows it; it opens a terminal on the `ssh <host>` alias from `modules/ssh`
  - **Wake** where the host has a `wol` relay this user can reach (`ssh <relay> wake-<host>`); refused with a notification while the host's plug is off (nothing to wake: use Power on)
  - **Power on** / **Power off** where the host is powered through a smart plug (registry `hosts.<host>.plug`, [[shelly-plug]]): `plug-<name> on|off` straight from this host. Off asks "Cut power to <host>?" first, and is refused for the host the dashboard runs on. No toggle: it would race a stale row. A plug that is off gives the NIC no standby power, so Wake only works after Power on; whether Power on alone boots the host is the BIOS's "restore on AC loss" setting.
  - **Check if a rebuild is needed**: evaluates the host's toplevel from `dashboard.flake` with the locked inputs, and compares it with the system it runs
  - **Details** (the host's last announcement first, when its relay has one)
  - **Copy address**
