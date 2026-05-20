# Reverse Proxy

Generic nginx reverse proxy with Let's Encrypt TLS termination. Each entry in `vhosts` becomes a public HTTPS virtual host whose traffic is forwarded to an upstream URL (typically a loopback service on the same host).

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
```

After deploy, `https://headscale.example.com` is served by nginx with a valid Let's Encrypt cert and proxied to `127.0.0.1:8080`.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable nginx + ACME and any declared vhosts |
| acmeEmail | string | (required) | Email used for ACME registration and expiry notices |
| openFirewall | bool | true | Open TCP 80 and 443 in `networking.firewall` |
| vhosts | attrset | { } | Vhost definitions keyed by short label |
| vhosts.\<name\>.domain | string | (required) | FQDN served by this vhost |
| vhosts.\<name\>.upstream | string | (required) | Upstream URL (e.g. `http://127.0.0.1:8080`) |
| vhosts.\<name\>.extraConfig | lines | "" | Extra nginx config inserted into the `location /` block |

## Notes

- TLS uses HTTP-01 challenges, so the host must be reachable on TCP 80 from the public internet and DNS for each `domain` must resolve to this host.
- `recommendedProxySettings`, `recommendedTlsSettings`, and `recommendedGzipSettings` are enabled. WebSocket upgrade headers (`proxyWebsockets = true`) are set on every vhost, which is what services like headscale need.
- Each vhost gets `forceSSL = true`; the HTTP listener only serves the ACME challenge and a redirect to HTTPS.
- This module does not manage DNS, port forwarding, or certificate revocation.
