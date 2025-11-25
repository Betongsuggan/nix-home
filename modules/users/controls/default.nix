{ config, lib, pkgs, ... }:
with lib;

{
  imports = [
    ./brightness
    ./volume
    ./media-player
    ./power
    ./utils
  ];

  options.controls = {
    enable = mkEnableOption "Enable system controls";

    windowManager = mkOption {
      description = "Window manager type for controls integration";
      type = types.enum [ "hyprland" "i3" "sway" "generic" ];
      default = "generic";
    };


    brightness = {
      enable = mkOption {
        description = "Enable brightness controls";
        type = types.bool;
        default = true;
      };

      backend = mkOption {
        description = "Brightness control backend";
        type = types.enum [ "light" "brightnessctl" ];
        default = "light";
      };

      notifications = mkOption {
        description = "Enable brightness change notifications";
        type = types.bool;
        default = true;
      };
    };

    volume = {
      enable = mkOption {
        description = "Enable volume controls";
        type = types.bool;
        default = true;
      };

      backend = mkOption {
        description = "Volume control backend";
        type = types.enum [ "pamixer" "pactl" ];
        default = "pamixer";
      };

      notifications = mkOption {
        description = "Enable volume change notifications";
        type = types.bool;
        default = true;
      };
    };

    mediaPlayer = {
      enable = mkOption {
        description = "Enable media player controls";
        type = types.bool;
        default = true;
      };

      notifications = mkOption {
        description = "Enable media player notifications";
        type = types.bool;
        default = true;
      };
    };

    power = {
      enable = mkOption {
        description = "Enable power management controls";
        type = types.bool;
        default = true;
      };

      confirmActions = mkOption {
        description = "Require confirmation for destructive power actions";
        type = types.bool;
        default = true;
      };

      notifications = mkOption {
        description = "Enable power action notifications";
        type = types.bool;
        default = true;
      };
    };

    utils = {
      enable = mkOption {
        description = "Enable utility notifications (time, battery, system info)";
        type = types.bool;
        default = true;
      };

      time = mkOption {
        description = "Enable time notifications";
        type = types.bool;
        default = true;
      };

      battery = mkOption {
        description = "Enable battery notifications";
        type = types.bool;
        default = true;
      };

      system = mkOption {
        description = "Enable system resource notifications";
        type = types.bool;
        default = true;
      };

      workspaces = mkOption {
        description = "Enable workspace notifications";
        type = types.bool;
        default = true;
      };

      autoScreenRotation = mkOption {
        description = "Enable automatic screen rotation";
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf config.controls.enable {
    # Auto-enable notifications when controls are enabled
    notifications.enable = mkDefault true;

    # Provide access to individual control modules through config.controls
    home.packages = with pkgs; [
      # Common dependencies for all controls
      coreutils
      gnugrep
      gnused
      gawk
      which
      procps
    ];
  };
}