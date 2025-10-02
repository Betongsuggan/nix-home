{ config, lib, pkgs, ... }:
with lib;

let
  walkerCfg = import ./config/config.nix;
  theme = import ./config/theme.nix { inherit (config) lib theme; };
in {
  options.walker = {
    enable = mkEnableOption "Enable Walker application launcher";
    runAsService = mkOption {
      type = types.bool;
      default = true;
      description = "Run Walker as a service for faster startup";
    };
  };
  config = mkIf config.walker.enable {

    home = {
      packages = with pkgs; [ walker unstable.bzmenu unstable.iwmenu ];

      file = {
        ".config/walker/config.json".text = walkerCfg;
        ".config/walker/themes/local.css".text = theme.css;
        ".config/walker/themes/local.json".text = theme.json;
      };
    };

    systemd.user.services.walker = mkIf config.walker.runAsService {
      Unit = {
        Description = "Walker Application Launcher";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session-pre.target" ];
      };

      Service = {
        ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
