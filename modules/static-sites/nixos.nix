{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.static-sites;

  # nginx `root` for a site: a store path whose only entry is the URL prefix,
  # symlinked to the site's package. `root` + request URI then lands inside the
  # package without `alias`, which is the form gixy accepts under a prefix location.
  siteRoot =
    name: site:
    pkgs.linkFarm "static-site-${name}" [
      {
        name = removePrefix "/" site.path;
        path = site.package;
      }
    ];
in
{
  options.my.static-sites = {
    sites = mkOption {
      default = { };
      description = ''
        Static sites served under a URL prefix of an existing reverse-proxy domain.
        Each site is a store path (its `package`) mounted at `https://<domain><path>/`.
        The domain's vhost (cert, redirects) comes from `my.reverse-proxy`; this module only adds locations.
      '';
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              domain = mkOption {
                type = types.str;
                default = inputs.self.lib.domain;
                defaultText = literalExpression "lib.domain";
                description = "FQDN of the vhost to mount the site on. MUST appear in `my.reverse-proxy.domains`.";
              };

              path = mkOption {
                type = types.strMatching "/[A-Za-z0-9._-]+";
                default = "/${name}";
                defaultText = literalExpression ''"/''${name}"'';
                description = "URL prefix, one segment, without a trailing slash (e.g. `/wow`).";
              };

              package = mkOption {
                type = types.package;
                description = "Derivation whose output is the site root (index.html at the top).";
              };

              cacheControl = mkOption {
                type = types.str;
                default = "public, max-age=300";
                description = "Cache-Control header for every file of the site.";
              };

              extraConfig = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Extra nginx config for the site's location block. Sites are public by default;
                  pass the tailnet allow/deny block here (`lib.tailnet.nginxAllowOnly [ ]`) to restrict one.
                '';
              };
            };
          }
        )
      );
    };
  };

  config = mkIf (cfg.sites != { }) {
    assertions = mapAttrsToList (name: site: {
      assertion = config.my.reverse-proxy.enable && elem site.domain config.my.reverse-proxy.domains;
      message = "static-sites.${name}: domain '${site.domain}' must be listed in my.reverse-proxy.domains";
    }) cfg.sites;

    services.nginx.virtualHosts = mkMerge (
      mapAttrsToList (name: site: {
        ${site.domain} = {
          # `/wow` -> `/wow/`, so the site's relative links resolve under the prefix
          locations."= ${site.path}".return = "301 ${site.path}/";
          locations."${site.path}/" = {
            root = siteRoot name site;
            index = "index.html";
            extraConfig = ''
              add_header Cache-Control "${site.cacheControl}";
              limit_except GET HEAD { deny all; }
              ${site.extraConfig}
            '';
          };
        };
      }) cfg.sites
    );
  };
}
