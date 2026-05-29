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

    domains = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "rydback.net" "vpn.rydback.net" ];
      description = ''
        Domains to issue HTTP-01 certs for. Each needs a public A record
        pointing at this host and TCP 80 reachable from the internet. A vhost
        will exist for each domain — either from `vhosts` or, if no vhost
        matches, a default 404 stub that still serves the ACME challenge.
      '';
    };

    vhosts = mkOption {
      default = { };
      description = ''
        Reverse-proxy vhosts keyed by short label. Each vhost's `domain` MUST
        appear in `domains`.
      '';
      type = types.attrsOf (types.submodule {
        options = {
          domain = mkOption {
            type = types.str;
            description = "FQDN this vhost serves. MUST appear in `domains`.";
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
    assertions = map (v: {
      assertion = elem v.domain cfg.domains;
      message = "reverse-proxy vhost domain '${v.domain}' must be listed in reverse-proxy.domains";
    }) (attrValues cfg.vhosts);

    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;

      virtualHosts =
        let
          vhostByDomain = mapAttrs' (_n: v: nameValuePair v.domain v) cfg.vhosts;
        in
        genAttrs cfg.domains (d:
          if vhostByDomain ? ${d} then {
            serverName = d;
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = vhostByDomain.${d}.upstream;
              proxyWebsockets = true;
              extraConfig = vhostByDomain.${d}.extraConfig;
            };
          } else {
            serverName = d;
            enableACME = true;
            forceSSL = true;
            locations."/".return = "404";
          }
        );
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 80 443 ];
  };
}
