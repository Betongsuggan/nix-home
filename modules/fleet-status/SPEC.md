# Fleet Status

Every host's status on one screen. Each host serves a small JSON status document on the tailnet, and tells its WoL relay before it suspends or shuts down, so an absent host reads as *asleep*, *shut down* or *no power* (its smart plug, [[shelly-plug]]) rather than tailscale's bare *offline*. An admin's launcher shows all hosts with their state, and offers SSH, wake, power, a rebuild check and details for each.

Both halves come from the standalone launcher flake ([github:Betongsuggan/launcher](https://github.com/Betongsuggan/launcher)): `services.fleet-status` (NixOS: status server, announcements) and `programs.launcher.fleet` (Home Manager: the dashboard). This module wraps them and feeds them the registry through `lib.fleetHosts`, so hosts and users set nothing by hand.

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
| dashboard.enable | Home Manager | bool | admin with the desktop profile | The dashboard and its Mod+G bind |
| dashboard.flake | Home Manager | str | `~/nix-home` | Checkout the rebuild check evaluates |
| dashboard.package | Home Manager | package (read-only) | | The dashboard command (`programs.launcher.fleet.package`) |

## The registry mapping (`lib.fleetHosts`)

`lib.fleetHosts { self; user ? null; plugCommand ? (_: null); }` turns the registry into the flake's `hosts` as seen from `self` by `user`:

| Field | From |
|---|---|
| address, tailnetName, tailnetIp | `lib.tailnet.fqdn`, `hostName`, `tailnetIp` |
| ssh | `lib.sshTargetsOf self user` allows it; the command is the ssh module's `ssh <host>` alias |
| wake | the host has a `wol` relay this user can reach: `wake-<host>` on the relay itself, else `ssh <relay> wake-<host>` |
| power | `plugCommand hosts.<host>.plug` (the HM wrapper passes `plug-<name>` from [[shelly-plug]] when this host has it): `on`, `off`, and a `status` that prints on/off and the watts |
| relay | `wol.relay` |

The NixOS wrapper calls it with `self` only (addresses, IPs and relays are all the server needs); the HM wrapper with the user and the plug commands.

## Behaviour

- **Status service**: a socket-activated systemd service (`fleet-status.socket`, `Accept=yes`, `DynamicUser`), so nothing runs between requests. The firewall opens its port on the tailscale interface only. Each request returns `battery`, `disk` (`/` used percent and free bytes), `uptime`, `backups` (each restic job's last finish and result), `system` (the running system), `rebootPending`, `rebuilt` (when the system profile last changed) and `peers` (what other hosts last announced, `{ <host>: { state: suspend|shutdown|resume, at } }`).
- **Announcements** (`announceTo`): `fleet-announce suspend` runs before `sleep.target`, `fleet-announce shutdown` is the `ExecStop` of a unit ordered after tailscaled so it runs while the tailnet is still up (reboots announce it too; the next boot's live status wins), `fleet-announce resume` runs from `powerManagement.resumeCommands`. Each is one `POST /state` to the relay's status port, by tailnet IP (no DNS on the way down), 3 s timeout so a missing relay never delays a suspend. The responder identifies the sender by `REMOTE_ADDR` against the fleet's tailnet IPs: anyone else gets 403, anything but the three states 400. Announcements live in `/var/lib/fleet-status/peers/<host>.json` on the relay.
- **Dashboard rows**: the registry's hosts. Those tailscale reports online are fetched in parallel (2 s timeout); asleep or absent ones aren't asked, so they don't hold the menu up (all are asked when `tailscale status` fails). Plugs are fetched alongside. A host that answers shows its status (plus ` · power 78 W` when it has a plug). One that doesn't is resolved in this order:
  | Row | Meaning |
  |---|---|
  | `⏻ desktop · no power` | its plug's relay is open |
  | `○ desktop · asleep since 3h · 19 W` | it announced `suspend` to its relay |
  | `⏼ desktop · shut down since 2d · 19 W` | it announced `shutdown` |
  | `? desktop · unreachable · seen 2d ago · 19 W` | powered, no announcement: crashed, or lost power while on |
  | `○ laptop · offline · seen 2d ago` | no plug, no announcement: tailscale's view is all there is |
  | `◐ … online, no status` / `✗ … not on the tailnet` | as before |
- **Actions**, from the host's entry: **SSH** (a terminal on the `ssh <host>` alias), **Wake** (refused with a notification while the host's plug is off), **Power on** / **Power off** (`plug-<name>`; off asks "Cut the power?" first and is refused for the host the dashboard runs on; no toggle, it would race a stale row), **Check if a rebuild is needed** (evaluates the host's toplevel from `dashboard.flake` and compares it with the running system), **Details** (the host's last announcement first), **Copy address**. Notifications go through `notify-send` (libnotify), which dunst and mako both take.
