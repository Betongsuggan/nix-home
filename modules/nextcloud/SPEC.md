# Nextcloud

Self-hosted file sync + collaboration suite. Backend for Google Workspace replacement: file storage, calendar (CalDAV), contacts (CardDAV), mail, notes, tasks, deck (kanban project boards), plus the OnlyOffice editor frontend (the editing happens in the [[onlyoffice]] document server). PostgreSQL via socket auth, Redis for memcache/locking, nginx vhost owned by the upstream `services.nextcloud` module and extended here with ACME + (optional) tailnet allow/deny.

## Usage

```nix
my.nextcloud = {
  enable        = true;
  domain        = "cloud.example.com";
  adminUser     = "betongsuggan";
  adminPassFile = config.sops.secrets."nextcloud-admin-pass".path;
  maxUploadSize = "10G";
  tailnetOnly   = true;
};

# Secrets are exposed to the nextcloud user via sops-nix:
sops.secrets."nextcloud-admin-pass" = {
  key   = "services/nextcloud-admin-pass";
  owner = "nextcloud";
  mode  = "0400";
};
```

Pair with the OnlyOffice [[onlyoffice]] module on a different hostname.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Nextcloud |
| domain | string | (required) | Public FQDN, becomes `hostName` + `overwritehost`. |
| adminUser | string | "root" | Initial admin username. Used only at first setup; immutable thereafter. |
| adminPassFile | path | (required) | File containing the initial admin password. Read only at first-boot setup. |
| maxUploadSize | string | "10G" | nginx + PHP upload size cap. PHP `memory_limit` is pinned separately to 512M. |
| tailnetOnly | bool | false | Apply tailnet `allow`/`deny all` at `/` and `~ \.php` location level. |
| sso.enable | bool | false | Log in through the identity provider ([[sso]], Kanidm) with the `user_oidc` app |
| sso.clientId | str | "nextcloud" | Kanidm client id; also the vault key `sso/clients/<id>` in `common.yaml` |
| sso.discoveryUri | str | `<my.sso.issuerFor clientId>/.well-known/openid-configuration` | Provider discovery document |
| sso.secretFile | str | sops `nextcloud-oidc-secret` | Client secret, readable by `nextcloud` |
| sso.passwordLogin | bool | true | Keep the password form beside the provider button (`allow_multiple_user_backends`) |

## Notes

- **Pinned major:** `pkgs.nextcloud33`. Bump exactly one major per upgrade — Nextcloud refuses cross-major jumps. nixpkgs keeps the previous major (currently `nextcloud32`) available to support stepwise upgrades. When NixOS 26.05 ships `nextcloud34`, change the pin to 34 in *one* commit, rebuild, then bump again to 35 only after that's verified.
- **Database:** PostgreSQL, created locally with socket auth (`database.createLocally = true; config.dbtype = "pgsql"`). No password file — the upstream module asserts password auth is incompatible with `createLocally`. Shares the same PostgreSQL instance with OnlyOffice (separate DBs and roles, both peer-authenticated).
- **Redis:** `configureRedis = true` enables a dedicated `nextcloud` redis server on a unix socket and configures it as the memcache.distributed + memcache.locking backend. Required for the `notify_push` app if it's ever added.
- **Extra apps:** `onlyoffice`, `calendar`, `contacts`, `deck`, `mail`, `notes`, `tasks` — all from `pkgs.nextcloud33Packages.apps`. `extraAppsEnable = true` means they're activated automatically at every `nextcloud-setup.service` run, so they survive rebuilds. The official appstore stays disabled while `extraApps` is non-empty — to install something not packaged in nixpkgs, use `pkgs.fetchNextcloudApp` and add it to `extraApps`, don't enable it from the web UI.
- **Deck:** the project tracker. Boards live in the Nextcloud DB, attachments under `/var/lib/nextcloud`, so the nightly pg dump + restic set already cover it. Cards with a due date show up in the Calendar app (toggle the Deck calendar there) and sync read-only over CalDAV. Due-date notifications ride on the existing `nextcloud-cron` timer. Suggested layout for a personal portfolio: one `Projects` board with stacks Idea / Active / Paused / Done, one card per project; a board per project only when it has real task volume. If this kanban-only model chafes (no priorities, labels are per board, no cross-board filters), the reserve plan is a Vikunja module at `projects.rydback.net`.
- **SSO (`sso.enable`):** the module registers the client at the identity provider itself (`my.sso.clients.<clientId>`: both `user_oidc` redirect URLs, landing page). The `user_oidc` app is added to `extraApps` and the oneshot `nextcloud-sso-provider.service` (after `nextcloud-setup`) declares the provider `Kanidm` with `occ user_oidc:provider` on every activation (it updates in place). `--unique-uid 0` with `preferred_username` as the user id makes an OIDC login land on the existing account of the same name (Kanidm's `birger` → Nextcloud's `birger`); user_oidc's default soft auto-provisioning then updates that account's display name and mail rather than creating a second user. `allow_local_remote_servers` is switched on because `id.rydback.net` resolves to this host's own tailnet address, which Nextcloud's SSRF guard treats as local. Password login stays available while `sso.passwordLogin` is true; the admin can always reach the form with `?direct=1`. PKCE (S256) and ES256 tokens work with user_oidc as shipped. Rotating the client secret: change the vault value, rebuild (Kanidm and Nextcloud both read the new file).
- **Reverse proxy:** the upstream `services.nextcloud` module creates `services.nginx.virtualHosts.<hostName>` with all the right locations and PHP-FPM wiring. This module merges in `enableACME` + `forceSSL` + (optional) `allow/deny` in two locations.
- **Tailnet-only mechanics:** `allow`/`deny all` is placed at *location* level (not server level) on `/` and `~ \.php(?:$|/)`. The auto-generated `^~ /.well-known/acme-challenge/` location has no allow/deny of its own, so a server-level `deny all;` would inherit and break HTTP-01; location-level rules don't inherit between sibling locations, so ACME stays open. Nextcloud's other locations either 404 hard-coded (admin paths), serve static assets, or fall through to `/index.php` (which hits the `~ \.php` deny). Public-facing surface is the static asset locations — those are not sensitive.
- **Trusted proxies:** not set. PHP-FPM receives requests from nginx via a local unix socket; `REMOTE_ADDR` is the actual client IP, no proxy chain to declare.
- **Mail (SMTP):** not configured. Once your mail host is up, set `services.nextcloud.settings.{mail_smtphost, mail_smtpport, ...}` + `services.nextcloud.secrets.mail_smtppassword` (do NOT use `settings.mail_smtppassword` — it lands in the Nix store, and the module asserts against this).
- **Data location:** `/var/lib/nextcloud` (the module's `home`/`datadir` default). Include this path in the host's backup set. The PostgreSQL DB is the other half — back it up via `services.postgresqlBackup` to a path also included in the restic set.
- **Admin UI:** `https://<domain>` for first-login as `adminUser`. The Nextcloud → ONLYOFFICE app's "Document Editing Service address" field must be set manually to `https://<onlyoffice-domain>` after first boot — saving that triggers a connectivity round-trip; the test must pass before editing works.
