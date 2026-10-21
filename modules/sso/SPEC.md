# SSO

One login for the self-hosted services: Kanidm as the identity provider on controller at `id.rydback.net`, tailnet-only. People, groups and the OAuth2/OIDC clients are declared in Nix (`services.kanidm.provision`), so a new service is a client entry here plus a few lines in its own module; nothing is clicked together in a web UI. The operator comes from the registry (`lib.operator.login`, `displayName`, `email`).

## Usage

```nix
my.sso = {
  enable = true;
  clients.grafana = {
    displayName = "Grafana";
    redirectUrls = [ "https://grafana.example.com/login/generic_oauth" ];
    landing = "https://grafana.example.com/";
  };
};
```

A consumer module on the same host registers its own client this way (`my.nextcloud.sso`, `my.monitoring.sso` do), together with any role group and the persons in it; only clients for services on other hosts are declared in the host file. A consumer then points at `config.my.sso.issuerFor "grafana"` (discovery at `<issuer>/.well-known/openid-configuration`), uses the client id `grafana`, and reads the same secret from the vault (`sso/clients/grafana` in `common.yaml`) under its own owner.

Requires `my.reverse-proxy` (the vhost and its Let's Encrypt cert) and `my.sops`. Like every other service name, `domain` needs a **public A record** (Route 53) pointing at controller's WAN address, or the HTTP-01 order fails and nginx serves a self-signed placeholder (browsers then refuse WebAuthn); and the `id` name in the host's `my.home-network.extraDnsRecords` so tailnet members resolve it to controller's tailnet address.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Run Kanidm and provision it |
| domain | str | `lib.sso.domain` (`id.<lib.domain>`) | Hostname and WebAuthn relying-party id. Changing it breaks every passkey; consumers on other hosts derive URLs from `lib.sso`, so it is a fleet constant |
| port | port | 8443 | Loopback port; nginx proxies `domain` to it over TLS |
| tailnetOnly | bool | true | Tailnet sources only on the vhost |
| persons | attrset | the operator (always present) | Who can log in: `displayName`, `mail`, extra `groups`. All are in `sso_users`. Other modules add role groups to a person with `persons.<login>.groups` |
| groups | list of str | `[ ]` | Role groups to create besides `sso_users`; membership is declared on the person, the claim on the client |
| admins | list of str | `[ lib.operator.login ]` | Members of Kanidm's built-in `idm_admins` |
| clients.\<id\> | submodule | | `displayName`, `redirectUrls`, `landing`, `scopes` (default openid profile email), `supplementaryScopes` (default groups), `disablePkce`, `legacyCrypto`, `secretFile`, `settings` (raw passthrough, e.g. `claimMaps`) |
| adminPasswordFile | str | sops `sso-admin-password` | Kanidm `admin` password. Vault `services/sso/admin-password` |
| idmAdminPasswordFile | str | sops `sso-idm-admin-password` | Kanidm `idm_admin` password. Vault `services/sso/idm-admin-password` |
| backupDir | str | `/var/backups/kanidm` | Kanidm's own nightly snapshots (01:00, 7 kept); this is the restic path, not `/var/lib/kanidm` |
| issuerFor | function (read-only) | `lib.sso.issuerFor` | `client → https://<domain>/oauth2/openid/<client>`; from another host use `inputs.self.lib.sso.issuerFor` |

## Setting up

1. **Vault.** Generate the passwords and one secret per client (`openssl rand -base64 48` each):
   - `secrets/controller.yaml`: `services.sso.admin-password`, `services.sso.idm-admin-password`
   - `secrets/common.yaml`: `sso.clients.<client>` for every entry in `clients` (the consumer's host reads the same key)

   Push, `nix flake update nix-vault`, rebuild controller. Provisioning runs on every start of `kanidm.service` and fails loudly if a secret file is missing.
2. **First login.** Persons are created without credentials. As `idm_admin` on controller:
   ```
   kanidm login -D idm_admin          # password from the vault
   kanidm person credential create-reset-token birger
   ```
   Open the printed URL at `https://id.rydback.net`, enrol a passkey (YubiKey or phone) and, if wanted, a password. Then `kanidm person credential update birger` later for changes, or the self-service page in the web UI.
3. **Services** switch to SSO one at a time in their own modules; each keeps its local admin login until the OIDC login is proven.

## Notes

- **TLS.** Kanidm refuses plain HTTP, including from a proxy, so it terminates TLS on loopback with the vhost's own certificate: the ACME cert for `domain` is owned by group `kanidm` (nginx is added to that group) and renewals reload both nginx and Kanidm (`ExecReload` sends SIGHUP). nginx proxies to `https://127.0.0.1:<port>` and Kanidm trusts `X-Forwarded-For` from loopback only (`http_client_address_info`).
- **Issuer per client.** Kanidm's OIDC issuer is `https://<domain>/oauth2/openid/<client>`, not the bare domain. Some services append `/.well-known/openid-configuration` themselves.
- **Usernames.** `preferShortUsername` is on for every client, so `preferred_username` is `birger`, not `birger@id.rydback.net`. That is what lets an OIDC login land on an existing account of the same name (Nextcloud user `birger`).
- **Scopes and groups.** Every person is in `sso_users`, which is granted `scopes` on each client; `supplementaryScopes` (default `groups`) ride along for role mapping. Per-service roles are Kanidm groups (`groups`) listed in a person's `groups` and mapped with `settings.claimMaps` on the client, e.g. `grafana_admins` → claim `grafana_role = ["Admin"]`. Group membership is overwritten from Nix on every start (except built-ins), so a role granted in the web UI does not survive a rebuild: grant it in Nix.
- **PKCE and crypto.** Kanidm defaults to PKCE required and ES256 tokens. `disablePkce` and `legacyCrypto` exist for clients that cannot cope; both lower security and are set per client, never globally.
- **Built-in groups.** `admins` is applied to `idm_admins` additively (`overwriteMembers = false`). Overwriting a built-in group's members removes `idm_admin` from it and locks the provisioner out half-way; this happened on the first deploy. If it ever happens again on a fresh instance, stop `kanidm.service`, wipe `/var/lib/kanidm`, start it: there is nothing to keep before the first login.
- **Backups.** `/var/lib/kanidm` is 0700 and the database is live; back up `backupDir`, which Kanidm writes consistently at 01:00, before restic runs at 01:45. Restore: `kanidmd restore -c <config> <file>` (see the Kanidm book).
- **Version.** `pkgs.kanidmWithSecretProvisioning_1_11`, pinned major. nixpkgs marks an end-of-life major insecure and evaluation stops; bump one major at a time after `kanidmd domain upgrade-check`.
- **The `deck` CLI** and other API clients keep their app passwords; SSO covers interactive logins.
