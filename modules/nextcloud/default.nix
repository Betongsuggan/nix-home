{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nextcloud;

  # Layered tailnet-only defence. Applied at *location* level (not server
  # level) so the auto-generated `^~ /.well-known/acme-challenge/` location
  # the nginx module emits remains open — it has no allow/deny of its own
  # and so would otherwise inherit a server-level `deny all;` and break
  # HTTP-01 renewals. The matching public DNS A record points at this
  # host's WAN IP; headscale's `extraDnsRecords` rewrites it to the host's
  # tailnet IP for tailnet members, so they reach nginx from a 100.x source
  # IP and pass the allow.
  tailnetOnlySnippet = ''
    # Loopback covers any same-host service that needs to reach Nextcloud
    # (e.g. OnlyOffice's callback to Nextcloud's WebDAV when saving a doc).
    # Linux routes connections to locally-assigned addresses over lo, so the
    # source IP nginx sees is 127.0.0.1 / ::1, not the tailnet IP.
    allow 127.0.0.1;
    allow ::1;
    allow 100.64.0.0/10;
    allow fd7a:115c:a1e0::/48;
    deny all;
  '';
in
{
  options.nextcloud = {
    enable = mkEnableOption "Nextcloud (file sync + collaboration suite)";

    domain = mkOption {
      type = types.str;
      example = "cloud.example.com";
      description = ''
        Public FQDN clients use to reach Nextcloud. Becomes
        `services.nextcloud.hostName` and `settings.overwritehost`. This
        module owns the nginx vhost — it adds ACME (HTTP-01) and forceSSL
        to the vhost the upstream `services.nextcloud` module creates.
      '';
    };

    adminUser = mkOption {
      type = types.str;
      default = "root";
      description = ''
        Initial admin username. Used only during the first
        `nextcloud-setup.service` run. Nextcloud uses this as an internal
        user ID too — it cannot be renamed later.
      '';
    };

    adminPassFile = mkOption {
      type = types.path;
      description = ''
        Path to a file containing the initial admin password (single line,
        no trailing newline). Read only during the first-boot setup.
        Typically a sops-nix decrypted path, e.g.
        `config.sops.secrets."nextcloud-admin-pass".path` with
        `owner = "nextcloud"; mode = "0400";`.
      '';
    };

    maxUploadSize = mkOption {
      type = types.str;
      default = "10G";
      description = ''
        Maximum upload size. Sets nginx `client_max_body_size` and PHP's
        `upload_max_filesize` / `post_max_size`. PHP's `memory_limit` is
        pinned to 512M separately (see config below) — the upstream module
        otherwise defaults `memory_limit` to this same value, which would
        let a single PHP request OOM the host.
      '';
    };

    tailnetOnly = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When true, restricts the nginx vhost to headscale tailnet source
        IPs. The allow/deny rules are placed inside the catch-all `/`
        location and the `~ \.php(?:$|/)` location — that covers every
        meaningful request path (Nextcloud's other locations fall through
        internally to `/index.php`, which hits the `~ \.php` deny). The
        auto-generated ACME challenge location is unaffected, so HTTP-01
        renewals keep working.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.nextcloud = {
      enable = true;
      hostName = cfg.domain;

      # Pin the major explicitly. Bump exactly one major per upgrade
      # (e.g. 33 → 34 when 34 lands; never 33 → 35). Nextcloud refuses
      # cross-major jumps; nixpkgs keeps the previous major available to
      # make stepwise upgrades possible.
      package = pkgs.nextcloud33;

      https = true;
      maxUploadSize = cfg.maxUploadSize;

      database.createLocally = true;
      configureRedis = true;

      config = {
        dbtype = "pgsql";
        adminuser = cfg.adminUser;
        adminpassFile = cfg.adminPassFile;
      };

      extraApps = with pkgs.nextcloud33Packages.apps; {
        inherit onlyoffice calendar contacts mail notes tasks;
      };
      extraAppsEnable = true;

      settings = {
        overwriteprotocol = "https";
        overwritehost = cfg.domain;
        default_phone_region = "SE";
      };

      # mkForce overrides the upstream default that mirrors `maxUploadSize`
      # (10G). That would let a single PHP request OOM the host.
      phpOptions.memory_limit = mkForce "512M";
    };

    # Extend (don't replace) the nginx vhost the upstream nextcloud module
    # already created at `cfg.hostName`. NixOS attrset merging adds ACME +
    # forceSSL alongside the upstream `locations` and `extraConfig`.
    services.nginx.virtualHosts.${cfg.domain} = {
      enableACME = true;
      forceSSL = true;
      locations = mkIf cfg.tailnetOnly {
        "/".extraConfig = mkAfter tailnetOnlySnippet;
        "~ \\.php(?:$|/)".extraConfig = mkAfter tailnetOnlySnippet;
      };
    };
  };
}
