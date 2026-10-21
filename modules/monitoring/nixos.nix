{
  config,
  lib,
  pkgs,
  inputs,
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
        "none"
        "Viewer"
        "Editor"
        "Admin"
      ];
      default = if cfg.sso.enable then "none" else "Viewer";
      defaultText = literalExpression ''if cfg.sso.enable then "none" else "Viewer"'';
      description = ''
        Role every visitor gets without logging in, or `none` to require a
        login. Without SSO the only login is the local `admin`, so anonymous
        Viewer is the usable default; with SSO everyone signs in and
        anonymous access goes away.
      '';
    };

    sso = {
      enable = mkEnableOption "logging in to Grafana through the identity provider (`my.sso`)";

      clientId = mkOption {
        type = types.str;
        default = "grafana";
        description = "Kanidm OAuth2 client id; also the vault key `sso/clients/<id>` in `common.yaml`.";
      };

      secretFile = mkOption {
        type = types.str;
        default = config.sops.secrets."grafana-oidc-secret".path;
        defaultText = literalExpression ''config.sops.secrets."grafana-oidc-secret".path'';
        description = "File with the client secret, readable by the `grafana` user.";
      };

      adminGroup = mkOption {
        type = types.str;
        default = "grafana_admins";
        description = "Kanidm group whose members get Grafana's Admin role; everyone else who logs in is a Viewer.";
      };

      admins = mkOption {
        type = types.listOf types.str;
        default = [ inputs.self.lib.operator.login ];
        defaultText = literalExpression "[ lib.operator.login ]";
        description = "Persons put into `adminGroup`.";
      };
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
        "auth.anonymous" = mkIf (cfg.anonymousRole != "none") {
          enabled = true;
          org_role = cfg.anonymousRole;
        };
        security = mkIf (cfg.environmentFile != null) {
          admin_password = "$__env{GF_SECURITY_ADMIN_PASSWORD}";
          secret_key = "$__env{GF_SECURITY_SECRET_KEY}";
        };
        # Kanidm issues one OIDC issuer per client; the role comes from the
        # `grafana_role` claim the client's claim map builds from the groups
        "auth.generic_oauth" =
          let
            idp = "https://${config.my.sso.domain}";
            issuer = config.my.sso.issuerFor cfg.sso.clientId;
          in
          mkIf cfg.sso.enable {
            enabled = true;
            name = "Kanidm";
            client_id = cfg.sso.clientId;
            client_secret = "$__file{${cfg.sso.secretFile}}";
            scopes = "openid profile email groups";
            auth_url = "${idp}/ui/oauth2";
            token_url = "${idp}/oauth2/token";
            api_url = "${issuer}/userinfo";
            use_pkce = true;
            use_refresh_token = true;
            allow_sign_up = true;
            login_attribute_path = "preferred_username";
            name_attribute_path = "name";
            email_attribute_path = "email";
            groups_attribute_path = "groups";
            role_attribute_path = "contains(grafana_role[*], 'Admin') && 'Admin' || 'Viewer'";
            allow_assign_grafana_admin = false;
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

    # The consumer owns its registration at the identity provider: the
    # client, the role group and who is in it
    my.sso = mkIf cfg.sso.enable {
      clients.${cfg.sso.clientId} = {
        displayName = "Grafana";
        redirectUrls = [ "https://${cfg.domain}/login/generic_oauth" ];
        landing = "https://${cfg.domain}/";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        settings.claimMaps.grafana_role = {
          joinType = "array";
          valuesByGroup.${cfg.sso.adminGroup} = [ "Admin" ];
        };
      };
      groups = [ cfg.sso.adminGroup ];
      persons = genAttrs cfg.sso.admins (_: {
        groups = [ cfg.sso.adminGroup ];
      });
    };

    assertions = [
      {
        assertion = cfg.sso.enable -> config.my.sso.enable;
        message = "my.monitoring.sso needs my.sso on the same host (the client, group and role claim are provisioned there)";
      }
    ];

    sops.secrets =
      mkIf (cfg.sso.enable && builtins.pathExists "${inputs.nix-vault}/secrets/common.yaml")
        {
          "grafana-oidc-secret" = {
            sopsFile = "${inputs.nix-vault}/secrets/common.yaml";
            key = "sso/clients/${cfg.sso.clientId}";
            owner = "grafana";
            mode = "0400";
          };
        };
  };
}
