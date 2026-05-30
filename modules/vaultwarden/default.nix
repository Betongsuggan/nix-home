{ config, lib, pkgs, ... }:

with lib;

let cfg = config.vaultwarden;
in {
  options.vaultwarden = {
    enable = mkEnableOption "Vaultwarden (Bitwarden-compatible password manager)";

    domain = mkOption {
      type = types.str;
      example = "vault.example.com";
      description = ''
        Public FQDN clients use to reach Vaultwarden. Becomes the `DOMAIN`
        env var. A reverse proxy must terminate TLS for this domain and
        forward to `127.0.0.1:<port>`.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8222;
      description = ''
        Loopback port Vaultwarden listens on. Reverse proxy upstream target.
      '';
    };

    environmentFile = mkOption {
      type = types.path;
      description = ''
        Path to a KEY=VALUE environment file. MUST define `ADMIN_TOKEN`
        (used to access the /admin endpoint). Typically a sops-nix decrypted
        file: store the env content as a multi-line secret in nix-vault and
        expose it via `sops.secrets.<name>.path` with `owner = "vaultwarden"`.
      '';
    };

    signupsAllowed = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether new user registration is allowed via the public signup
        endpoint. Default false (the secure end-state). Flip to true
        *briefly* during initial operator registration, then back to false
        and rebuild.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      environmentFile = cfg.environmentFile;
      config = {
        DOMAIN = "https://${cfg.domain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = cfg.port;
        SIGNUPS_ALLOWED = cfg.signupsAllowed;
        INVITATIONS_ALLOWED = false;
        WEB_VAULT_ENABLED = true;
      };
    };
  };
}
