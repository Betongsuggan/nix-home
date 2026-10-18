{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.dns-filter;
  self = inputs.self.lib.hosts.${config.my.common.host};
  lan = self.lan or null;

  hagezi =
    name:
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/${name}-onlydomains.txt";

  # "192.168.50.0/24" -> "50.168.192.in-addr.arpa"; only /24 is derived
  reverseZone =
    subnet:
    let
      parts = splitString "/" subnet;
      octets = splitString "." (head parts);
    in
    optional (length parts == 2 && last parts == "24") (
      concatStringsSep "." (reverseList (take 3 octets)) + ".in-addr.arpa"
    );

  # Upstream blocky dashboards, pinned. The exported JSON carries
  # `${DS_…}` placeholders that provisioning does not resolve, so they are
  # bound to the datasource uids `monitoring` provisions.
  blockyDocs =
    file: hash:
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/0xERR0R/blocky/ef95d592b323a06ad95ce10daeb53b534a8a8e79/docs/${file}";
      inherit hash;
    };
  dashboards = pkgs.runCommand "blocky-grafana-dashboards" { nativeBuildInputs = [ pkgs.jq ]; } ''
    mkdir -p $out
    jq 'del(.__inputs, .__requires, .__elements)' \
      ${blockyDocs "blocky-grafana.json" "sha256-8u5OYL3CWSdGCh4PNvyobsQ47gIqWc+4NULUOWRYFwI="} \
      | sed -e 's|''${DS_PROMETHEUS}|prometheus|g' \
            -e 's|''${VAR_BLOCKY_URL}|${toString cfg.apiUrl}|g' > $out/blocky.json
    jq 'del(.__inputs, .__requires, .__elements)' \
      ${blockyDocs "blocky-query-grafana-postgres.json" "sha256-j/YHpgly0qFj+hE2XzRXx04HOM3GxSvKVI6UNMq7Vtk="} \
      | sed -e 's|''${DS_POSTGRES}|blocky-querylog|g' > $out/blocky-query.json
  '';
in
{
  options.my.dns-filter = {
    enable = mkEnableOption "blocky: a filtering DNS resolver for the LAN and the tailnet";

    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ "tailscale0" ] ++ optional (lan != null) lan.interface;
      defaultText = literalExpression ''[ "tailscale0" ] ++ optional (lib.hosts.<host> ? lan) lib.hosts.<host>.lan.interface'';
      description = "Interfaces on which port 53 is opened. Blocky itself binds every address.";
    };

    upstreams = mkOption {
      type = types.listOf types.str;
      default = [
        "tcp-tls:dns.quad9.net"
        "tcp-tls:dns.mullvad.net"
      ];
      description = ''
        Resolvers blocky forwards to, in blocky's `[net:]host[:port]`
        syntax. Encrypted (`tcp-tls:` / `https:`) by default so the ISP sees
        no queries. Each hostname here needs an entry in `bootstrapDns`.
      '';
    };

    bootstrapDns = mkOption {
      type = types.listOf types.attrs;
      default = [
        {
          upstream = "tcp-tls:dns.quad9.net";
          ips = [
            "9.9.9.9"
            "149.112.112.112"
          ];
        }
        {
          upstream = "tcp-tls:dns.mullvad.net";
          ips = [ "194.242.2.2" ];
        }
      ];
      description = "How blocky resolves the upstream hostnames (and list URLs) before it can resolve anything itself.";
    };

    router = mkOption {
      type = types.nullOr types.str;
      default = if lan != null then lan.gateway else null;
      defaultText = literalExpression "lib.hosts.<host>.lan.gateway or null";
      description = ''
        LAN router, asked for reverse lookups so clients appear by name
        (DHCP hostname) in the query log and metrics instead of by IP.
      '';
    };

    reverseZones = mkOption {
      type = types.listOf types.str;
      default = if lan != null then reverseZone lan.subnet else [ ];
      defaultText = literalExpression "<in-addr.arpa zone of lib.hosts.<host>.lan.subnet, if /24>";
      description = "Reverse zones forwarded to `router`.";
    };

    blocklists = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {
        hagezi-pro = [ (hagezi "pro") ];
        lg-webos = [ (hagezi "native.lgwebos") ];
        samsung = [ (hagezi "native.samsung") ];
        roku = [ (hagezi "native.roku") ];
        amazon = [ (hagezi "native.amazon") ];
        xiaomi = [ (hagezi "native.xiaomi") ];
      };
      description = ''
        Named groups of denylist sources (URLs, files, or inline domains).
        Every group applies to every client unless `clientGroups` says
        otherwise.
      '';
    };

    allowlists = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      example = {
        hagezi-pro = [
          ''
            example.com
          ''
        ];
      };
      description = "Per-group allowlists; a domain listed here is never blocked by that group.";
    };

    clientGroups = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {
        default = attrNames cfg.blocklists;
      };
      defaultText = literalExpression "{ default = attrNames cfg.blocklists; }";
      description = ''
        Which blocklist groups apply to which clients (blocky
        `clientGroupsBlock`): keys are `default`, a client name glob, an IP
        or a CIDR.
      '';
    };

    customDomains = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "printer.home.example.com" = "192.168.50.20";
      };
      description = "Static name → address answers (blocky `customDNS.mapping`).";
    };

    httpPort = mkOption {
      type = types.port;
      default = 4000;
      description = "Loopback port for blocky's HTTP API and Prometheus `/metrics`.";
    };

    apiUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://dns.example.com";
      description = ''
        Where a browser on the tailnet reaches blocky's HTTP API (a
        reverse-proxy vhost onto `httpPort`). Only used by the Grafana
        dashboard's enable/disable-blocking buttons.
      '';
    };

    queryLog = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Log every query to a local PostgreSQL database `blocky` (what the Grafana query dashboard reads).";
      };
      retentionDays = mkOption {
        type = types.int;
        default = 30;
        description = "Days of query log kept.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.blocky = {
      enable = true;
      settings = {
        ports = {
          dns = [ "53" ];
          http = "127.0.0.1:${toString cfg.httpPort}";
        };

        upstreams = {
          groups.default = cfg.upstreams;
          strategy = "parallel_best";
          init.strategy = "fast";
        };
        bootstrapDns = cfg.bootstrapDns;

        blocking = {
          denylists = cfg.blocklists;
          allowlists = cfg.allowlists;
          clientGroupsBlock = cfg.clientGroups;
          blockType = "zeroIp";
          blockTTL = "1m";
          loading = {
            # Serve immediately, load lists in the background, and keep
            # serving if a source is down: a GitHub outage must not take
            # the house's DNS with it.
            strategy = "fast";
            refreshPeriod = "4h";
            downloads = {
              timeout = "4m";
              attempts = 5;
              cooldown = "30s";
            };
          };
        };

        caching = {
          minTime = "5m";
          maxTime = "30m";
          prefetching = true;
        };

        customDNS = mkIf (cfg.customDomains != { }) {
          mapping = cfg.customDomains;
          filterUnmappedTypes = true;
        };

        # Client names from the router's DHCP table, both for the
        # per-client log/metrics and for in-addr.arpa lookups.
        clientLookup = mkIf (cfg.router != null) { upstream = cfg.router; };
        conditional = mkIf (cfg.router != null && cfg.reverseZones != [ ]) {
          mapping = genAttrs cfg.reverseZones (_: cfg.router);
        };

        prometheus.enable = true;

        queryLog = mkIf cfg.queryLog.enable {
          type = "postgresql";
          # Peer auth over the socket: the DynamicUser is named `blocky`
          target = "postgres://blocky@/blocky?host=/run/postgresql";
          logRetentionDays = cfg.queryLog.retentionDays;
          flushInterval = "30s";
        };

        log.level = "info";
      };
    };

    networking.firewall.interfaces = genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    });

    services.postgresql = mkIf cfg.queryLog.enable {
      enable = true;
      ensureDatabases = [ "blocky" ];
      ensureUsers = [
        {
          name = "blocky";
          ensureDBOwnership = true;
        }
      ]
      ++ optional config.my.monitoring.enable { name = "grafana"; };
    };

    systemd.services.blocky = {
      after = optional cfg.queryLog.enable "postgresql.service";
      requires = optional cfg.queryLog.enable "postgresql.service";
    };

    # Grafana reads the query log: a read-only grant on whatever tables
    # blocky creates (now and later, via default privileges).
    systemd.services.blocky-querylog-grafana-grant =
      mkIf (cfg.queryLog.enable && config.my.monitoring.enable)
        {
          description = "Grant Grafana read access to blocky's query log";
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
            ExecStart = pkgs.writeShellScript "blocky-querylog-grafana-grant" ''
              ${config.services.postgresql.package}/bin/psql -d blocky -v ON_ERROR_STOP=1 <<'SQL'
                GRANT USAGE ON SCHEMA public TO grafana;
                GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana;
                ALTER DEFAULT PRIVILEGES FOR ROLE blocky IN SCHEMA public GRANT SELECT ON TABLES TO grafana;
              SQL
            '';
          };
        };

    my.monitoring = mkIf config.my.monitoring.enable {
      scrapeTargets.blocky = "127.0.0.1:${toString cfg.httpPort}";
      dashboards = {
        blocky = "${dashboards}/blocky.json";
      }
      // optionalAttrs cfg.queryLog.enable {
        blocky-query = "${dashboards}/blocky-query.json";
      };
      datasources = optional cfg.queryLog.enable {
        name = "Blocky query log";
        uid = "blocky-querylog";
        type = "grafana-postgresql-datasource";
        access = "proxy";
        url = "/run/postgresql";
        user = "grafana";
        jsonData = {
          database = "blocky";
          sslmode = "disable";
        };
      };
    };
  };
}
