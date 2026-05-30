{ config, lib, pkgs, ... }:

with lib;

let cfg = config.headscale;
in {
  options.headscale = {
    enable = mkEnableOption "Headscale Tailscale coordination server";

    domain = mkOption {
      type = types.str;
      example = "headscale.example.com";
      description = "Public domain clients use to reach headscale (server_url host).";
    };

    baseDomain = mkOption {
      type = types.str;
      example = "tailnet.example.com";
      description = ''
        MagicDNS base domain. MUST differ from `domain` (headscale enforces this).
        Node FQDNs become `<name>.<baseDomain>`.
      '';
    };

    listenPort = mkOption {
      type = types.port;
      default = 8080;
      description = "Loopback port headscale listens on (nginx proxies to this).";
    };

    metricsPort = mkOption {
      type = types.port;
      default = 9090;
      description = "Loopback port for Prometheus metrics.";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "birger" ];
      description = ''
        Headscale users to provision on startup. Each name is created via
        `headscale users create <name>` if it does not already exist. Removing
        a name from this list does NOT delete the user — do that manually.
      '';
    };

    extraDnsRecords = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "vault.example.com";
            description = "FQDN to override on tailnet clients.";
          };
          type = mkOption {
            type = types.str;
            default = "A";
            description = "DNS record type (A or AAAA).";
          };
          value = mkOption {
            type = types.str;
            example = "100.64.0.2";
            description = "Address to return. Typically a tailnet IP.";
          };
        };
      });
      default = [ ];
      description = ''
        Extra DNS records pushed to tailnet clients. Use this to make a
        public hostname resolve to a tailnet IP for member devices, so a
        tailnet-only nginx vhost is reachable by its real (cert-bearing)
        name. Requires clients to accept pushed DNS (tailscale's
        `--accept-dns`, set by the `tailnet` module).
      '';
    };

    derp = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Run an embedded DERP relay region (additive to Tailscale's public DERP map).";
      };

      stunPort = mkOption {
        type = types.port;
        default = 3478;
        description = "UDP STUN port for the embedded DERP server.";
      };

      regionCode = mkOption {
        type = types.str;
        default = "controller";
        description = "Short region code for the embedded DERP region.";
      };

      regionName = mkOption {
        type = types.str;
        default = "Controller embedded DERP";
        description = "Human-readable region name.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = cfg.listenPort;

      settings = {
        server_url = "https://${cfg.domain}";
        metrics_listen_addr = "127.0.0.1:${toString cfg.metricsPort}";

        dns = {
          magic_dns = true;
          base_domain = cfg.baseDomain;
          nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
          extra_records = cfg.extraDnsRecords;
        };

        # `derp.urls` is left at the upstream default (Tailscale's public DERP
        # map), so the embedded region is additive. Extra `server` keys are
        # passed through via the freeform settings type.
        derp.server = mkIf cfg.derp.enable {
          enabled = true;
          region_id = 999;
          region_code = cfg.derp.regionCode;
          region_name = cfg.derp.regionName;
          stun_listen_addr = "0.0.0.0:${toString cfg.derp.stunPort}";
        };
      };
    };

    environment.systemPackages = [ pkgs.headscale ];

    networking.firewall.allowedUDPPorts = mkIf cfg.derp.enable [ cfg.derp.stunPort ];

    systemd.services.headscale-provision-users = mkIf (cfg.users != [ ]) {
      description = "Provision headscale users declared in Nix";
      wantedBy = [ "multi-user.target" ];
      after = [ "headscale.service" ];
      requires = [ "headscale.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.headscale pkgs.jq ];
      script = ''
        set -eu
        existing=$(headscale users list --output json | jq -r '(. // []) | .[].name')
        for u in ${concatStringsSep " " cfg.users}; do
          if ! echo "$existing" | grep -qx "$u"; then
            echo "Creating headscale user: $u"
            headscale users create "$u"
          fi
        done
      '';
    };
  };
}
