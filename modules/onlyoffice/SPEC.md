# OnlyOffice

ONLYOFFICE Document Server — the in-browser editing backend that [[nextcloud]]'s `onlyoffice` app talks to. Runs its own document service (`onlyoffice-docservice`) + converter (`onlyoffice-converter`) under the `onlyoffice` system user, backed by PostgreSQL (`onlyoffice` DB on socket auth) and RabbitMQ. The upstream `services.onlyoffice` module creates a full nginx vhost at the configured hostname; this module wraps it with the same secrets / TLS / tailnet-restriction patterns used elsewhere in the repo.

## Usage

```nix
onlyoffice = {
  enable        = true;
  domain        = "office.example.com";
  jwtSecretFile = config.sops.secrets."onlyoffice-jwt".path;
  nonceFile     = config.sops.secrets."onlyoffice-nonce".path;
  tailnetOnly   = true;
};

sops.secrets = {
  "onlyoffice-jwt"   = { key = "services/onlyoffice-jwt";   owner = "onlyoffice"; mode = "0400"; };
  "onlyoffice-nonce" = { key = "services/onlyoffice-nonce"; owner = "nginx";      mode = "0400"; };
};
```

Then in Nextcloud's admin UI (`https://<nextcloud-domain>/settings/admin/onlyoffice`), set:
- **Document Editing Service address**: `https://<onlyoffice-domain>`
- **Secret key**: the same value as `onlyoffice-jwt`

Saving triggers a connectivity round-trip — that's the integration test.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the OnlyOffice document server |
| domain | string | (required) | Public FQDN. Must be distinct from Nextcloud's hostname. |
| jwtSecretFile | path | (required) | File with the JWT signing secret. Read by `onlyoffice-docservice` prestart as user `onlyoffice`. |
| nonceFile | path | (required) | File with the literal nginx snippet `set $secure_link_secret "<random>";` — `include`d at config parse time, so it must be readable by `nginx`. |
| tailnetOnly | bool | false | Apply tailnet `allow`/`deny all` at `/`, `(doc|downloadas)`, and `/cache/files` location level. |

## Notes

- **JWT secret must match Nextcloud's ONLYOFFICE app config exactly.** A mismatch produces silent failures (the editor loads but documents won't open). Same value, no whitespace, no trailing newline.
- **Nonce file format:** literal nginx config, e.g. `set $secure_link_secret "abc...";`. Generate the value with `openssl rand -hex 32` and wrap in the `set` statement. The file is `include`d by nginx — invalid syntax breaks the whole config.
- **PostgreSQL + RabbitMQ:** the upstream module enables both via `mkDefault true`. Postgres is shared with Nextcloud (separate DB + role, socket auth). RabbitMQ is OnlyOffice-only and listens on localhost.
- **No persistent state worth backing up:** `/var/lib/onlyoffice` holds only transient editing/document-conversion state. Real documents live in [[nextcloud]]'s data directory and are backed up there. Skip `/var/lib/onlyoffice` from restic.
- **nginx vhost** is owned by the upstream `services.onlyoffice` module — it sets up all the static asset aliases, the `/cache/files` secure-link gate, the `/internal` + `/info` 127.0.0.1-only locations, and the docservice proxy_pass. This module adds ACME + forceSSL + (optional) tailnet allow/deny on top via attrset merging.
- **Tailnet-only mechanics:** `allow`/`deny all` is at *location* level (not server level) for the same reason as [[nextcloud]] — server-level deny would inherit into the auto-generated ACME challenge location and break HTTP-01 renewals. Static editor assets (web-apps, sdkjs, fonts, dictionaries) deliberately stay open; they're public UI JavaScript and have no privileged behavior. The actual document data path (`/cache/files`) is signed with `secure_link` *and* the tailnet rule.
- **OnlyOffice + reverse proxy** is notoriously fragile with non-nginx fronts (Caddy/Traefik need an `X-Forwarded-Proto https` workaround). We use nginx, so the upstream module's `proxy_set_header` block handles all of it correctly. No additional headers needed.
- **Upstream port:** docservice defaults to `127.0.0.1:8000`. On a host that also runs `wake-proxy` with port 8000 in its set (wake-proxy binds `0.0.0.0:8000`), set `services.onlyoffice.port` to something free (e.g. 8765) before enabling this module — otherwise OnlyOffice fails to bind at startup.
