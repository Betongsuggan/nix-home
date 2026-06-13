# Wake Proxy

A wake-on-LAN-aware TCP proxy. A single long-running Go process listens on a set of ports on its tailnet interface and forwards each connection to the same port on a configured upstream host. When the upstream isn't reachable the proxy fires a WoL magic packet, waits up to `wakeTimeoutSec` for the port to open, then bridges. An "upstream alive" flag is cached so a browser bursting 50 parallel sub-requests doesn't pay 50 probes (nor 50 WoL packets).

Designed to front a sleepable host that runs heavy services (in this repo: the `ai-server` module on desktop). Clients always address the always-on proxy host; they never need to know whether the upstream is awake.

## Usage

```nix
wake-proxy = {
  enable = true;
  targetMac = "aa:bb:cc:dd:ee:ff";
  targetHost = "100.64.0.5";       # tailnet IP of the sleepy host
  ports = [ 11434 ];               # extend with 8081, 8188, 8000 etc. as services are added
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable           | bool              | false  | Enable the proxy |
| targetMac        | string            | (req.) | MAC of the upstream NIC that's powered during sleep |
| targetHost       | string            | (req.) | Hostname/IP used to probe and proxy to the upstream |
| ports            | list of port      | `[ 11434 ]` | TCP ports to listen on; forwarded to the same port upstream |
| wakeTimeoutSec   | int               | 60     | Seconds to wait for the upstream port after sending WoL |
| broadcastAddress | nullable string   | null   | Override WoL broadcast (default `255.255.255.255`) |

## How it works

One `systemd.services.wake-proxy` unit runs the Go binary built from `src/main.go` (`pkgs.buildGoModule`, no external deps). On startup the process:

1. Opens a TCP listener on each configured port and accepts connections concurrently.
2. Maintains a single `atomic.Bool` for "upstream alive", primed at boot by probing the first configured port and refreshed every 30 seconds.
3. On each new connection: if the cached flag says alive, dials the upstream immediately. Otherwise takes a mutex (so the first concurrent connection wakes the host while the rest queue), re-probes, sends WoL via `pkgs.wakeonlan`, and polls once per second until the upstream answers or `wakeTimeoutSec` elapses.
4. Once dialed, copies bytes bidirectionally with explicit `CloseWrite` half-close on each side so neither nginx nor the upstream sees an RST during teardown.

The listening ports are only opened on `tailscale0` — never on the LAN or the wider internet.

## Notes

- One long-lived process instead of a `systemd-socket-activated` per-connection bash. The previous design worked for single-curl traffic but produced RSTs to nginx under SPA-style burst loads (Open WebUI loading 50+ JS files on initial render).
- TCP-level proxy: handles HTTP, WebSocket upgrades, gRPC, and anything else that's plain TCP. No TLS termination here — front it with the existing `reverse-proxy` module if you want a public HTTPS URL.
- The upstream's tailscale daemon also sleeps with the host; using its tailnet IP as `targetHost` means the same address starts responding again once it wakes.
- Hardening: `DynamicUser`, `ProtectSystem=strict`, `ProtectHome=true`, `NoNewPrivileges=true`. The Go binary needs no state on disk.

## Verification

From a third tailnet host (i.e. neither the proxy nor the upstream):

```bash
# Make sure upstream is asleep
ssh <upstream> systemctl suspend

# First request: triggers WoL, expect a multi-second delay
time curl http://<proxy>:11434/api/tags

# Immediate second request: upstream already awake, should be fast
time curl http://<proxy>:11434/api/tags
```

Logs:

```bash
journalctl -u wake-proxy -f
# expect lines like:
#   listening on :11434 -> 100.64.0.5:11434
#   upstream 100.64.0.5 unreachable; sending WoL
#   upstream 100.64.0.5 back up
```
