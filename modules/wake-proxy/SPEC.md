# Wake Proxy

A wake-on-LAN-aware TCP proxy. The proxy host listens on a set of ports on its tailnet interface; each incoming connection probes the upstream and, if it isn't responding, sends a WoL magic packet to a configured MAC, waits up to `wakeTimeoutSec` for the upstream port to open, then bridges the connection with `socat`.

Designed to front a sleepable host that runs heavy services (in this repo: the `ai-server` module on desktop). Clients always address the always-on proxy host; they never need to know whether the upstream is awake.

## Usage

```nix
wake-proxy = {
  enable = true;
  targetMac = "aa:bb:cc:dd:ee:ff";
  targetHost = "100.64.0.5";       # tailnet IP of the sleepy host
  ports = [ 11434 ];               # Ollama (extend with 8080 etc. as services are added)
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

For each port `p` in `ports`:

- `systemd.sockets."wake-proxy-<p>"` listens on `0.0.0.0:<p>` with `Accept = true`.
- For every accepted connection, systemd starts an instance of the template `systemd.services."wake-proxy-<p>@"`.
- The instance runs a small shell script that:
  1. Probes `targetHost:<p>` with `nc -z -w1`.
  2. If down, sends `wakeonlan <targetMac>` (optionally with `-i <broadcastAddress>`).
  3. Polls the probe every second until it succeeds or `wakeTimeoutSec` elapses.
  4. `exec`s `socat - TCP:<targetHost>:<p>`, bridging the socket-activated stdin/stdout to the upstream.

The listening ports are only opened on `tailscale0` — never on the LAN or the wider internet.

## Notes

- Per-connection model. A handful of parallel connections during a wake will each send their own magic packet; harmless.
- TCP-level proxy: handles HTTP, WebSocket upgrades, gRPC, and anything else that's plain TCP. No TLS termination here — front it with the existing `reverse-proxy` module if you want a public HTTPS URL.
- The upstream's tailscale daemon also sleeps with the host; using its tailnet IP as `targetHost` means the same address starts responding again once it wakes.

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

`journalctl -u 'wake-proxy-11434@*'` on the proxy shows one journal entry per connection, including any WoL/probe output.
