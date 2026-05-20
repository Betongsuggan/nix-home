{ config, lib, pkgs, ... }:

with lib;

let cfg = config.tailscale-client;
in {
  options.tailscale-client = {
    enable = mkEnableOption "Tailscale client joined to a headscale coordination server";

    loginServer = mkOption {
      type = types.str;
      example = "https://headscale.example.com";
      description = "URL of the headscale control server.";
    };

    authKeyFile = mkOption {
      type = types.path;
      description = ''
        Path to a file containing the preauth key. Typically a sops-decrypted
        secret path, e.g. `config.sops.secrets."headscale-preauthkey".path`.
      '';
    };

    extraUpFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--accept-routes" "--ssh" ];
      description = "Extra flags passed to `tailscale up` on first registration.";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = cfg.authKeyFile;
      extraUpFlags = [ "--login-server=${cfg.loginServer}" ] ++ cfg.extraUpFlags;
    };
  };
}
