# Network Monitor

Sends desktop notifications for network events: Wi-Fi connect/disconnect (with SSID), ethernet connect/disconnect, loss/restoration of internet connectivity, and tailscale up/down. Runs as a systemd user service that watches NetworkManager and the tailscale interface.

## Usage

```nix
network-monitor.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable network event notifications |

## Notes

- Automatically enables the `notifications` module when active; all events use the `network` notification category (shared stack tag, so rapid event bursts replace each other instead of stacking).
- Requires NetworkManager on the system (the `networkmanager` system module); device events come from `nmcli monitor`, filtered to wifi/ethernet devices.
- The Wi-Fi "SSID" is the NetworkManager connection profile name, which equals the SSID for normally-created profiles.
- Connectivity loss is reported when NetworkManager connectivity drops from `full` to `none`/`limited`; the state is seeded at service start so restarts don't re-announce.
- Tailscale up/down is detected via `ip monitor address` on `tailscale0` (tailscaled is a system service NetworkManager doesn't manage; the TUN operstate is unreliable, so the tailnet address appearing/disappearing is used instead). On hosts without tailscale the watch simply never fires.
- Runs as `network-monitor.service` bound to `graphical-session.target`, restarting on failure.
