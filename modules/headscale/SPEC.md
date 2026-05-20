# Headscale

Self-hosted [headscale](https://github.com/juanfont/headscale) coordination server (open-source Tailscale control plane). Wraps `services.headscale` with practical defaults, declarative user provisioning, and an embedded DERP relay region.

## Usage

```nix
reverse-proxy = {
  enable = true;
  acmeEmail = "you@example.com";
  vhosts.headscale = {
    domain = "headscale.example.com";
    upstream = "http://127.0.0.1:8080";
  };
};

headscale = {
  enable = true;
  domain = "headscale.example.com";
  baseDomain = "tailnet.example.com";
  users = [ "alice" "bob" ];
};
```

After deploy, clients connect with:

```
sudo tailscale up --login-server=https://headscale.example.com --auth-key=<preauth>
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable headscale |
| domain | string | (required) | Public domain for `server_url` (clients connect to `https://<domain>`) |
| baseDomain | string | (required) | MagicDNS base domain; MUST differ from `domain` |
| listenPort | port | 8080 | Loopback port headscale listens on |
| metricsPort | port | 9090 | Loopback port for Prometheus metrics |
| users | list of string | [ ] | Users to provision idempotently via `headscale users create` |
| derp.enable | bool | true | Run an embedded DERP relay region |
| derp.stunPort | port | 3478 | UDP STUN port for the embedded DERP server |
| derp.regionCode | string | "controller" | Short region code |
| derp.regionName | string | "Controller embedded DERP" | Human-readable region name |

## Prerequisites

1. **Reverse proxy with TLS** — headscale's control protocol requires HTTPS. Pair this module with `reverse-proxy` (or any nginx config) that terminates TLS for `domain` and proxies to `http://127.0.0.1:<listenPort>` with WebSocket upgrade support.
2. **DNS** — an A/AAAA record for `domain` must point at this host.
3. **Ports** — TCP 80/443 (Let's Encrypt + HTTPS) and UDP `derp.stunPort` (default 3478) must be reachable from clients.

## Provisioning users and preauth keys

Users are declarative (via the `users` option). **Preauth keys are not** — headscale issues them, you can't choose their value. Workflow:

```bash
# On the controller, once per client:
sudo headscale preauthkeys create -u <user> --reusable -e 8760h
#   -> tskey-auth-XXXXXXXX...
```

The resulting key is what a client passes to `tailscale up --auth-key=...`. For a fully declarative pipeline, encrypt it into the `nix-secrets` flake and consume it on the client via the `tailscale-client` module.

## Notes

- The embedded DERP region is added on top of Tailscale's public DERP map (`derp.urls` is left at upstream default). Clients can use either as a fallback when direct connections fail.
- Headscale auto-generates its noise and DERP private keys under `/var/lib/headscale/` on first start. No secrets are needed in Nix for the server itself.
- Removing a name from `users` does not delete the headscale user; use `sudo headscale users destroy <name>` to do that.
- This module assigns to `networking.firewall.allowedUDPPorts` directly. The existing `firewall` module's `tcpPorts`/`udpPorts` lists merge via Nix list-typed option merging, so a host can keep `firewall.udpPorts = []` and still have the STUN port open.
