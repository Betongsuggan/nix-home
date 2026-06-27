{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.onlyoffice;

  # Same per-location tailnet-only pattern as [[nextcloud]]. Applied to the
  # catch-all `/` (proxies to docservice), the document `(doc|downloadas)`
  # endpoint, and the signed `/cache/files` download path. The static editor
  # assets (web-apps/sdkjs/fonts/...) are deliberately left open — they're
  # plain UI JavaScript with no privileged behavior, and headscale's DNS
  # rewrite gives the layered defence regardless.
  tailnetOnlySnippet = ''
    # Loopback covers Nextcloud's server-side JWT handshake — its PHP-FPM
    # runs on the same host and Linux routes the local connection over lo,
    # so the source IP nginx sees is 127.0.0.1 / ::1, not the tailnet IP.
    allow 127.0.0.1;
    allow ::1;
    allow 100.64.0.0/10;
    allow fd7a:115c:a1e0::/48;
    deny all;
  '';
in
{
  options.onlyoffice = {
    enable = mkEnableOption "OnlyOffice Document Server (collaborative editing backend)";

    domain = mkOption {
      type = types.str;
      example = "office.example.com";
      description = ''
        Public FQDN for the document server. MUST be different from
        Nextcloud's hostname — OnlyOffice owns its full nginx vhost root.
      '';
    };

    jwtSecretFile = mkOption {
      type = types.path;
      description = ''
        Path to a file containing the JWT signing secret (single line).
        The EXACT same value must be entered in Nextcloud's ONLYOFFICE
        app config (admin UI → ONLYOFFICE → "Secret key"). Mismatched
        secrets silently break document loading. Read at activation by
        the `onlyoffice-docservice` prestart, which runs as user
        `onlyoffice` — typically a sops-nix path with
        `owner = "onlyoffice"; mode = "0400";`.
      '';
    };

    nonceFile = mkOption {
      type = types.path;
      description = ''
        Path to a file containing an nginx config snippet that sets the
        `$secure_link_secret` variable used to sign internal cache download
        URLs. Format (with trailing semicolon):

            set $secure_link_secret "<random>";

        Generate the random part with e.g. `openssl rand -hex 32`. nginx
        runs as user `nginx` and reads this file via `include` at config
        parse time, so the file must be readable by `nginx` — typically a
        sops-nix path with `owner = "nginx"; mode = "0400";`.
      '';
    };

    tailnetOnly = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When true, applies tailnet `allow`/`deny all` at location level on
        `/`, `(doc|downloadas)`, and `/cache/files`. Static editor assets
        stay open (see module comment). Auto-generated ACME challenge
        location is unaffected, so HTTP-01 renewals keep working.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.onlyoffice = {
      enable = true;
      hostname = cfg.domain;
      jwtSecretFile = cfg.jwtSecretFile;
      securityNonceFile = cfg.nonceFile;
    };

    # Extend the nginx vhost the upstream onlyoffice module creates at
    # `cfg.hostname`. The upstream module fills in all the static-asset
    # alias locations, the `/cache/files` secure-link block, and the
    # docservice proxy_pass — we just add ACME, forceSSL, and the
    # optional tailnet allow/deny on top.
    services.nginx.virtualHosts.${cfg.domain} = {
      enableACME = true;
      forceSSL = true;
      locations = mkIf cfg.tailnetOnly {
        "/".extraConfig = mkAfter tailnetOnlySnippet;
        # Location keys must match upstream verbatim (string-keyed merge).
        "~ ^(\\/[\\d]+\\.[\\d]+\\.[\\d]+[\\.|-][\\w]+)?(\\/(doc|downloadas)\\/.*)".extraConfig =
          mkAfter tailnetOnlySnippet;
        "~* ^(\\/cache\\/files.*)(\\/.*)".extraConfig = mkAfter tailnetOnlySnippet;
      };
    };
  };
}
