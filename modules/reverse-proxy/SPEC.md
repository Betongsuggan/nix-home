# Reverse Proxy

Nginx with HTTP-01 Let's Encrypt certs. You list the domains you want certs for; vhosts that match a domain proxy to an upstream, domains without a vhost get a 404 stub.

## Usage

```nix
reverse-proxy = {
  enable = true;
  acmeEmail = "you@example.com";
  domains = [ "example.com" "vpn.example.com" ];
  vhosts.headscale = {
    domain = "vpn.example.com";
    upstream = "http://127.0.0.1:8080";
  };
};
```

`example.com` gets a cert and a 404 vhost. `vpn.example.com` gets a cert and proxies to the upstream.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable nginx + ACME and any declared vhosts |
| acmeEmail | string | (required) | Email for ACME registration |
| openFirewall | bool | true | Open TCP 80 and 443 |
| domains | list of string | [ ] | Domains to issue HTTP-01 certs for. Each needs a public A record and TCP 80 reachable. |
| vhosts | attrset | { } | Vhost definitions keyed by short label |
| vhosts.\<name\>.domain | string | (required) | FQDN, must be in `domains` |
| vhosts.\<name\>.upstream | string | (required) | Upstream URL |
| vhosts.\<name\>.extraConfig | lines | "" | Extra nginx config in the `location /` block |

## Notes

- Per-domain HTTP-01 only. Wildcards are not supported (they require DNS-01).
- Certs auto-renew. No manual rotation.
- Each vhost gets `forceSSL = true` and WebSocket upgrade headers.
