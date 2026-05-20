{ config, lib, pkgs, ... }:

with lib;

let cfg = config.reverse-proxy;
in {
  options.reverse-proxy = {
    enable = mkEnableOption "Nginx reverse proxy with Let's Encrypt TLS";

    acmeEmail = mkOption {
      type = types.str;
      description = "Email for Let's Encrypt registration and expiry notices.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open TCP 80 and 443 in the firewall.";
    };

    vhosts = mkOption {
      default = { };
      description = "Virtual hosts, keyed by short label.";
      type = types.attrsOf (types.submodule {
        options = {
          domain = mkOption {
            type = types.str;
            description = "Fully-qualified domain name for the vhost.";
          };

          upstream = mkOption {
            type = types.str;
            example = "http://127.0.0.1:8080";
            description = "Upstream URL that nginx proxies to.";
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra nginx config lines inserted into the `location /` block.";
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;

      virtualHosts = mapAttrs (_name: v: {
        serverName = v.domain;
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = v.upstream;
          proxyWebsockets = true;
          extraConfig = v.extraConfig;
        };
      }) cfg.vhosts;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 80 443 ];
  };
}
