# Networking

Configures NetworkManager with iwd as the Wi-Fi backend. Sets up automatic wireless connectivity. On laptops it also gets a captive portal's login page in front of the user, which the tailnet's DNS setup otherwise makes impossible.

## Usage

```nix
my.network-manager.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable network management |
| captivePortal.enable | bool | false (`true` under `my.profiles.laptop`) | Detect a captive portal when an interface comes up, switch tailnet DNS off while it is in the way, open its login page in the session and switch DNS back on once the network is open |

## Captive portals

On the tailnet the only resolver a member has is controller's (headscale overrides local DNS so that `dns-filter` applies everywhere, see `modules/headscale`). A guest network with a login page blocks everything but its own portal until you have logged in, including the path to controller, so every DNS lookup on the laptop hangs: the browser never gets as far as an HTTP request the portal could redirect, and NetworkManager's own connectivity check (which uses the system resolver) reports "limited" instead of "portal". Nothing opens the login page and typing a URL does not help.

With `captivePortal.enable`:

1. A NetworkManager dispatcher runs `captive-login open` whenever an interface gets a DHCP nameserver (not `tailscale0`), and `captive-login restore` when it goes down.
2. `captive-login` resolves a plain-HTTP probe (`connectivitycheck.gstatic.com/generate_204`) through **the network's own nameserver** and connects by address, so the probe works whatever the system resolver does. `204` means online; a redirect or a page in its place means a portal.
3. On a portal it runs `tailscale set --accept-dns=false` (NetworkManager then writes the DHCP nameservers to `resolv.conf`), leaves the portal URL in `/run/captive-portal/url`, and starts a transient `captive-portal-wait` unit that re-probes every 5 s for up to 20 minutes.
4. A user path unit watches that directory and `xdg-open`s the URL in the session, so the login page appears in the default browser. No notification: the page is the notification.
5. When the probe returns `204` (or the interface goes down) tailnet DNS is switched back on and the state is cleared. If the laptop was rebooted mid-login, the next online network heals it: `open` notices tailnet DNS is off with no portal in sight and turns it on.

By hand: `captive-login` (same as `open`, re-executes itself through sudo), `captive-login probe`, `captive-login restore`. The state lives in `/run/captive-portal` and is gone after a reboot.

Limits: a portal network on the same subnet as an accepted tailnet route sends the probe through the tailnet instead of the local gateway; that is a routing question, not this module's. Advertised LAN ranges should therefore stay away from the consumer-router defaults (`192.168.0/1.0/24`), which guest and office networks use. Browsers that upgrade `http://` to HTTPS on their own (Chromium's HTTPS-First mode) fall back to HTTP after a timeout on a portal, which can take a few seconds.

## Notes

- The hostname is not set here: every host gets `networking.hostName` from its `lib/default.nix` registry entry (see `lib/mk-host.nix`).

- Uses iwd instead of wpa_supplicant for Wi-Fi, with `AutoConnect` and automatic `wlan0` interface creation enabled.
- Desktop notifications for network events are provided by the separate `network-monitor` user module.
