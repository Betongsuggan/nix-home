{ config, lib, pkgs, inputs, ... }:
with lib;


let
  walkerCfg = import ./config/config.nix;
  theme = import ./config/theme.nix { inherit (config) lib theme; };
in
{
  options.walker = {
    enable = mkEnableOption "Enable Walker application launcher";
    runAsService = mkOption {
      type = types.bool;
      default = true;
      description = "Run Walker as a service for faster startup";
    };
    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Configuration options for Walker";
    };
    style = mkOption {
      type = types.str;
      default = '''';
      description = "Custom CSS styling for Walker";
    };
  };
  config = mkIf config.walker.enable {
    # Install Walker package
    home-manager.users.${config.user} = {
      home = {
        packages = with pkgs;
          [
            walker
          ];

        # Create configuration directory
        file = {
          ".config/walker/config.json".text = builtins.toJSON (recursiveUpdate
            walkerCfg
            config.walker.config);

          ".config/walker/themes/local.css".text = theme.css;
          ".config/walker/themes/local.json".text = theme.json;
        };
      };
      # Create systemd user service for Walker
      systemd.user.services.walker = mkIf config.walker.runAsService {
        Unit = {
          Description = "Walker Application Launcher";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session-pre.target" ];
        };

        Service = {
          ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
