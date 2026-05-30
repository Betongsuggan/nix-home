# Vaultwarden

Self-hosted Bitwarden-compatible password manager. Backend for the Bitwarden clients on every device — clients keep an encrypted local copy and work offline, so this service only needs to be up for *sync*.

## Usage

```nix
vaultwarden = {
  enable = true;
  domain = "vault.example.com";
  environmentFile = config.sops.secrets."vaultwarden-env".path;
  signupsAllowed = false; # flip to true briefly during first-run registration
};

# Reverse proxy terminates TLS and restricts access to the tailnet:
reverse-proxy.domains = [ "vault.example.com" ];
reverse-proxy.vhosts.vaultwarden = {
  domain = "vault.example.com";
  upstream = "http://127.0.0.1:8222";
  extraConfig = ''
    allow 100.64.0.0/10;
    allow fd7a:115c:a1e0::/48;
    deny all;
  '';
};
```

The env file referenced by `environmentFile` MUST define `ADMIN_TOKEN`. Store it as a multi-line sops secret:

```yaml
# nix-vault/secrets/<host>.yaml
services:
  vaultwarden-env: |
    ADMIN_TOKEN=<output of `openssl rand -base64 48`>
```

Then expose it to NixOS:

```nix
sops.secrets."vaultwarden-env" = {
  key = "services/vaultwarden-env";
  owner = "vaultwarden";
  mode = "0400";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Vaultwarden |
| domain | string | (required) | Public FQDN (e.g. `vault.example.com`). Sets `DOMAIN`. |
| port | port | 8222 | Loopback port. Reverse-proxy upstream target. |
| environmentFile | path | (required) | KEY=VALUE env file. Must define `ADMIN_TOKEN`. |
| signupsAllowed | bool | false | Allow public signup endpoint. Flip true briefly during operator registration. |

## Notes

- **Data location:** `/var/lib/vaultwarden` (NixOS systemd `StateDirectory`). SQLite DB lives here along with attachments and Sends. Include this path in the host's backup set.
- **Tailnet-only:** Vaultwarden binds 127.0.0.1; access control happens at the nginx vhost level via `allow`/`deny`. The vhost still needs a public DNS A record and ACME HTTP-01 reachability — but `/.well-known/acme-challenge` is a different nginx location that NixOS handles at higher precedence than `/`, so the deny rule doesn't block cert renewal.
- **No SMTP:** until the mail server is online, password resets and email verifications won't send. Acceptable for a single-operator instance — you have direct admin-token access to reset things via `/admin`. Revisit once mail is up.
- **Emergency exports:** with no proper backup workstream yet, the operator should download an encrypted export from the web vault on a regular cadence (weekly) and store it on an offline USB. Loss of the host's disk then costs at most a week of new entries.
- **Admin endpoint:** `https://<domain>/admin` — auth via `ADMIN_TOKEN`. Use for user management, server config inspection, and (importantly) creating the first user if `signupsAllowed = false` from the start.
