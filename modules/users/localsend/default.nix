{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.localsend;
in {
  options.localsend = {
    enable = mkEnableOption "Enable Localsend for LAN file transfer";

    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically start Localsend with desktop session";
    };

    cli = mkOption {
      type = types.bool;
      default = false;
      description = "Also install jocalsend terminal client";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [ localsend ] ++ optional cfg.cli jocalsend;

    # Systemd user service to autostart localsend with the graphical session
    systemd.user.services.localsend = mkIf cfg.autostart {
      Unit = {
        Description = "LocalSend - LAN file transfer";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.localsend}/bin/localsend_app --hidden";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
