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
        Applied via `tailscale set` on every daemon start, so changes take
        effect on rebuild. Emptying the list does NOT withdraw previously
        advertised routes — run `tailscale set --advertise-routes=` once for
        that. Routes must additionally be approved on the headscale side
        (declaratively via `headscale.autoApprovedRoutes`, or manually).
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
      # Unlike up-flags (registration only), set-flags are applied by the
      # nixpkgs tailscaled-set service on every daemon start, so route changes
      # converge on rebuild without re-registering the node.
      extraSetFlags = optional (cfg.advertiseRoutes != [ ])
        "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}";
    };
  };
}
