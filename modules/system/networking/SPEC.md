# Networking

Configures NetworkManager with iwd as the Wi-Fi backend. Sets up automatic wireless connectivity and includes a network notifier utility.

## Usage

```nix
networkmanager = {
  enable = true;
  hostName = "my-machine";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable network management |
| hostName | string | "nixos" | Hostname of the system |

## Notes

- Uses iwd instead of wpa_supplicant for Wi-Fi, with `AutoConnect` and automatic `wlan0` interface creation enabled.
- A localhost entry for `bits.execute-api.localhost.localstack.cloud` is added to `/etc/hosts` (for LocalStack development).
- The network notifier script is a placeholder and not yet functional.
