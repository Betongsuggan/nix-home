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

    advertiseRoutes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.1.0/24" ];
      description = ''
        Subnets to advertise to the tailnet (subnet router). Also enables
        kernel IP forwarding via services.tailscale.useRoutingFeatures.
        Like all up-flags this is applied at registration only; changing it
        later requires `tailscale set --advertise-routes=...` on the host.
        Routes must additionally be approved on the headscale side.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = cfg.authKeyFile;
      useRoutingFeatures = mkIf (cfg.advertiseRoutes != [ ]) "server";
      extraUpFlags =
        [ "--login-server=${cfg.loginServer}" ]
        ++ optional (cfg.advertiseRoutes != [ ])
          "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}"
        ++ cfg.extraUpFlags;
    };
  };
}
