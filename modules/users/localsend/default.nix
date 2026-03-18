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

    # XDG autostart entry for localsend
    xdg.configFile."autostart/localsend.desktop" = mkIf cfg.autostart {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=LocalSend
        Exec=localsend_app --hidden
        Terminal=false
        StartupNotify=false
        X-GNOME-Autostart-enabled=true
      '';
    };
  };
}
