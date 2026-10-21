# monitoring

Prometheus and Grafana on one host, both bound to loopback, as a sink for other modules: a module that has something to show registers a scrape target, a datasource and a dashboard here, and the host puts a tailnet-only vhost in front of Grafana. First consumer: [[dns-filter]].

## Usage

```nix
my.monitoring = {
  enable = true;
  domain = "grafana.example.com";
  environmentFile = config.sops.secrets."grafana-env".path;
};

sops.secrets."grafana-env" = {
  key = "services/grafana-env";
  owner = "root";
  mode = "0400";
};

my.reverse-proxy.domains = [ "grafana.example.com" ];
my.reverse-proxy.vhosts.grafana = {
  domain = "grafana.example.com";
  upstream = "http://127.0.0.1:3000";
  extraConfig = inputs.self.lib.tailnet.nginxAllowOnly [ ];
};
```

The env file holds Grafana's two secrets (generate each with `openssl rand -base64 32`):

```yaml
# nix-vault/secrets/<host>.yaml
services:
  grafana-env: |
    GF_SECURITY_ADMIN_PASSWORD=<password for the `admin` login>
    GF_SECURITY_SECRET_KEY=<key Grafana encrypts stored secrets with>
```

A module contributes like this:

```nix
my.monitoring = mkIf config.my.monitoring.enable {
  scrapeTargets.myservice = "127.0.0.1:9100";
  dashboards.myservice = ./dashboard.json;      # datasource uid "prometheus"
  datasources = [ { name = "…"; uid = "…"; type = "…"; url = "…"; } ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Run Prometheus + Grafana |
| domain | str | (required) | FQDN Grafana is served under; becomes `server.domain` / `root_url`. |
| port | port | 3000 | Grafana loopback port (reverse-proxy upstream). |
| prometheusPort | port | 9091 | Prometheus loopback port. Not 9090: headscale's metrics live there. |
| retention | str | `"90d"` | Prometheus TSDB retention. |
| scrapeTargets | attrs of str | `{ }` | job name → `host:port` serving `/metrics`, scraped every 30 s. |
| scrapeConfigs | list of attrs | `[ ]` | Raw Prometheus `scrape_config` entries for what `scrapeTargets` can't express (probe-style exporters: `metrics_path`, `params`, `relabel_configs`). First user: [[shelly-plug]]. |
| dashboards | attrs of path | `{ }` | name → dashboard JSON, provisioned read-only. Datasource references must use provisioned uids (`prometheus`, or one from `datasources`). |
| datasources | list of attrs | `[ ]` | Extra datasources in Grafana's provisioning format. Prometheus is always provisioned as the default with uid `prometheus`. |
| anonymousRole | `Viewer` / `Editor` / `Admin` | `Viewer` | Role every visitor gets without logging in. |
| sso.enable | bool | false | Log in through the identity provider ([[sso]]); registers the client, the role group and its members there |
| sso.clientId | str | "grafana" | Kanidm client id; vault key `sso/clients/<id>` in `common.yaml` |
| sso.secretFile | str | sops `grafana-oidc-secret` | Client secret, readable by `grafana` |
| sso.adminGroup | str | "grafana_admins" | Kanidm group that maps to Grafana's Admin role; other logins are Viewers |
| sso.admins | list of str | `[ lib.operator.login ]` | Persons put into `adminGroup` |
| environmentFile | null or path | null | `GF_SECURITY_ADMIN_PASSWORD` + `GF_SECURITY_SECRET_KEY`. Without it Grafana runs with its defaults (`admin`/`admin`, public secret key), which is wrong even on a tailnet. |

## Notes

- **Access model.** The reverse proxy's tailnet-only rule is the access control, and anonymous visitors get `anonymousRole`. With `sso.enable` the login page offers "Sign in with Kanidm" (`auth.generic_oauth`: PKCE, per-client issuer, `preferred_username` as login, role from the `grafana_role` claim that Kanidm builds from the person's groups; `role_attribute_path` maps `Admin` and falls back to Viewer). The local `admin` (password from the env file) stays as the break-glass login. Requires `my.sso` on the same host. Provisioned dashboards cannot be edited or deleted from the UI (`allowUiUpdates = false`, `disableDeletion = true`): change the JSON in Nix instead, or save a copy under a new name.
- **Dashboards exported from Grafana** ("export for sharing externally") carry `${DS_…}` placeholders and an `__inputs` block that file provisioning does not resolve. Substitute the uids and strip `__inputs` at build time (see [[dns-filter]] for the pattern) before handing the file over.
- **Datasources** live in Grafana's own SQLite at `/var/lib/grafana`; so do users and any dashboards saved from the UI. Nothing here is in the backup set on purpose: the provisioned state is rebuilt from Nix, and the metrics are re-collected.
- **No telemetry.** `analytics.reporting_enabled`, update checks and feedback links are off.
- **PostgreSQL datasources over the socket:** `url = "/run/postgresql"`, `user = "grafana"`, `jsonData.sslmode = "disable"`, with the contributing module responsible for the role and its grants (see [[dns-filter]]).
