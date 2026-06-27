# Nextcloud

Self-hosted file sync + collaboration suite. Backend for Google Workspace replacement: file storage, calendar (CalDAV), contacts (CardDAV), mail, notes, tasks, plus the OnlyOffice editor frontend (the editing happens in the [[onlyoffice]] document server). PostgreSQL via socket auth, Redis for memcache/locking, nginx vhost owned by the upstream `services.nextcloud` module and extended here with ACME + (optional) tailnet allow/deny.

## Usage

```nix
nextcloud = {
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

## Notes

- **Pinned major:** `pkgs.nextcloud33`. Bump exactly one major per upgrade — Nextcloud refuses cross-major jumps. nixpkgs keeps the previous major (currently `nextcloud32`) available to support stepwise upgrades. When NixOS 26.05 ships `nextcloud34`, change the pin to 34 in *one* commit, rebuild, then bump again to 35 only after that's verified.
- **Database:** PostgreSQL, created locally with socket auth (`database.createLocally = true; config.dbtype = "pgsql"`). No password file — the upstream module asserts password auth is incompatible with `createLocally`. Shares the same PostgreSQL instance with OnlyOffice (separate DBs and roles, both peer-authenticated).
- **Redis:** `configureRedis = true` enables a dedicated `nextcloud` redis server on a unix socket and configures it as the memcache.distributed + memcache.locking backend. Required for the `notify_push` app if it's ever added.
- **Extra apps:** `onlyoffice`, `calendar`, `contacts`, `mail`, `notes`, `tasks` — all from `pkgs.nextcloud33Packages.apps`. `extraAppsEnable = true` means they're activated automatically at every `nextcloud-setup.service` run, so they survive rebuilds. The official appstore stays disabled while `extraApps` is non-empty — to install something not packaged in nixpkgs, use `pkgs.fetchNextcloudApp` and add it to `extraApps`, don't enable it from the web UI.
- **Reverse proxy:** the upstream `services.nextcloud` module creates `services.nginx.virtualHosts.<hostName>` with all the right locations and PHP-FPM wiring. This module merges in `enableACME` + `forceSSL` + (optional) `allow/deny` in two locations.
- **Tailnet-only mechanics:** `allow`/`deny all` is placed at *location* level (not server level) on `/` and `~ \.php(?:$|/)`. The auto-generated `^~ /.well-known/acme-challenge/` location has no allow/deny of its own, so a server-level `deny all;` would inherit and break HTTP-01; location-level rules don't inherit between sibling locations, so ACME stays open. Nextcloud's other locations either 404 hard-coded (admin paths), serve static assets, or fall through to `/index.php` (which hits the `~ \.php` deny). Public-facing surface is the static asset locations — those are not sensitive.
- **Trusted proxies:** not set. PHP-FPM receives requests from nginx via a local unix socket; `REMOTE_ADDR` is the actual client IP, no proxy chain to declare.
- **Mail (SMTP):** not configured. Once your mail host is up, set `services.nextcloud.settings.{mail_smtphost, mail_smtpport, ...}` + `services.nextcloud.secrets.mail_smtppassword` (do NOT use `settings.mail_smtppassword` — it lands in the Nix store, and the module asserts against this).
- **Data location:** `/var/lib/nextcloud` (the module's `home`/`datadir` default). Include this path in the host's backup set. The PostgreSQL DB is the other half — back it up via `services.postgresqlBackup` to a path also included in the restic set.
- **Admin UI:** `https://<domain>` for first-login as `adminUser`. The Nextcloud → ONLYOFFICE app's "Document Editing Service address" field must be set manually to `https://<onlyoffice-domain>` after first boot — saving that triggers a connectivity round-trip; the test must pass before editing works.
