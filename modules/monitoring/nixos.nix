{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.monitoring;

  dashboardDir = pkgs.linkFarm "grafana-dashboards" (
    mapAttrsToList (name: path: {
      name = "${name}.json";
      inherit path;
    }) cfg.dashboards
  );
in
{
  options.my.monitoring = {
    enable = mkEnableOption "Prometheus + Grafana, loopback-bound, for other modules to feed";

    domain = mkOption {
      type = types.str;
      example = "grafana.example.com";
      description = "FQDN Grafana is served under (a reverse-proxy vhost onto `port`).";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Loopback port Grafana listens on.";
    };

    prometheusPort = mkOption {
      type = types.port;
      default = 9091;
      description = "Loopback port Prometheus listens on (9090 is headscale's metrics port).";
    };

    retention = mkOption {
      type = types.str;
      default = "90d";
      description = "Prometheus TSDB retention.";
    };

    scrapeTargets = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        blocky = "127.0.0.1:4000";
      };
      description = "Prometheus scrape jobs: job name → `host:port` exposing `/metrics`. Modules add their own.";
    };

    scrapeConfigs = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        Raw Prometheus `scrape_config` entries, for jobs `scrapeTargets`
        can't express (probe-style exporters with `metrics_path`, `params`
        or `relabel_configs`). Modules add their own.
      '';
    };

    dashboards = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = "Grafana dashboards to provision: name → dashboard JSON file. Provisioned dashboards are read-only in the UI.";
    };

    datasources = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        Extra Grafana datasources (provisioning-file entries). Prometheus is
        always provisioned as the default datasource with uid `prometheus`.
      '';
    };

    anonymousRole = mkOption {
      type = types.enum [
        "Viewer"
        "Editor"
        "Admin"
      ];
      default = "Viewer";
      description = "Role every visitor gets without logging in. Access control is the reverse proxy's job (tailnet-only).";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Env file for Grafana, typically sops-decrypted, with
        `GF_SECURITY_ADMIN_PASSWORD` and `GF_SECURITY_SECRET_KEY`. Without
        it the admin login is Grafana's default and the secret key is the
        public default.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = cfg.prometheusPort;
      retentionTime = cfg.retention;
      globalConfig.scrape_interval = "30s";
      scrapeConfigs =
        mapAttrsToList (job: target: {
          job_name = job;
          static_configs = [ { targets = [ target ]; } ];
        }) cfg.scrapeTargets
        ++ cfg.scrapeConfigs;
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = cfg.port;
          domain = cfg.domain;
          root_url = "https://${cfg.domain}";
        };
        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
          check_for_plugin_updates = false;
          feedback_links_enabled = false;
        };
        "auth.anonymous" = {
          enabled = true;
          org_role = cfg.anonymousRole;
        };
        security = mkIf (cfg.environmentFile != null) {
          admin_password = "$__env{GF_SECURITY_ADMIN_PASSWORD}";
          secret_key = "$__env{GF_SECURITY_SECRET_KEY}";
        };
      };

      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              uid = "prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://127.0.0.1:${toString cfg.prometheusPort}";
              isDefault = true;
            }
          ]
          ++ cfg.datasources;
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "nix";
              type = "file";
              disableDeletion = true;
              allowUiUpdates = false;
              options.path = dashboardDir;
            }
          ];
        };
      };
    };

    systemd.services.grafana.serviceConfig.EnvironmentFile = mkIf (cfg.environmentFile != null) [
      cfg.environmentFile
    ];
  };
}
