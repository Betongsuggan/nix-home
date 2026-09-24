# Networking

Configures NetworkManager with iwd as the Wi-Fi backend. Sets up automatic wireless connectivity.

## Usage

```nix
my.network-manager.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable network management |

## Notes

- The hostname is not set here: every host gets `networking.hostName` from its `lib/default.nix` registry entry (see `lib/mk-host.nix`).

- Uses iwd instead of wpa_supplicant for Wi-Fi, with `AutoConnect` and automatic `wlan0` interface creation enabled.
- Desktop notifications for network events are provided by the separate `network-monitor` user module.
