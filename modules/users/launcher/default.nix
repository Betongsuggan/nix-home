{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

  # Main launcher dmenu function - delegates to backend
  launcherDmenuCmd = args:
    if cfg.backend == "wofi" then
      cfg.wofi.buildDmenuCmd args
    else if cfg.backend == "rofi" then
      cfg.rofi.buildDmenuCmd args
    else if cfg.backend == "walker" then
      cfg.walker.buildDmenuCmd args
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

  # Main launcher show function - delegates to backend
  launcherShowCmd = args:
    if cfg.backend == "wofi" then
      cfg.wofi.buildShowCmd args
    else if cfg.backend == "rofi" then
      cfg.rofi.buildShowCmd args
    else if cfg.backend == "walker" then
      cfg.walker.buildShowCmd args
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

  # WiFi launcher - delegates to backend-specific implementation
  launcherWifiCmd = { additionalArgs ? [ ] }:
    if cfg.backend == "wofi" then
      "${cfg.wofi.wifi}/bin/wifi-control"
    else if cfg.backend == "rofi" then
      "${cfg.rofi.wifi}/bin/wifi-control"
    else if cfg.backend == "walker" then
      "${pkgs.unstable.iwmenu}/bin/iwmenu --launcher walker --spaces 2 ${
        concatStringsSep " " additionalArgs
      }"
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

  # Bluetooth launcher - delegates to backend-specific implementation
  launcherBluetoothCmd = { additionalArgs ? [ ] }:
    if cfg.backend == "wofi" then
      "${cfg.wofi.bluetooth}/bin/bluetooth-control"
    else if cfg.backend == "rofi" then
      "${cfg.rofi.bluetooth}/bin/bluetooth-control"
    else if cfg.backend == "walker" then
      "${pkgs.unstable.bzmenu}/bin/bzmenu --launcher walker --spaces 2 ${
        concatStringsSep " " additionalArgs
      }"
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

in {
  imports = [ ./wofi ./rofi ./walker ];

  options.launcher = {
    enable = mkEnableOption "launcher system";

    backend = mkOption {
      type = types.enum [ "wofi" "rofi" "walker" ];
      default = "walker";
      description = "Which launcher to use";
    };

    dmenu = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate dmenu-style launcher commands.

        Usage:
          config.launcher.dmenu {
            prompt = "Select an option";
            password = false;
            insensitive = true;
            multiSelect = false;
            allowImages = true;
            additionalArgs = [ "--width" "500" ];
          }

        Returns a shell command string.
      '';
    };

    show = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate application launcher commands.

        Usage:
          config.launcher.show {
            mode = "drun";  # or "run", "applications", etc.
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    wifi = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate WiFi network selection launcher.

        Usage:
          config.launcher.wifi {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    bluetooth = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate Bluetooth device selection launcher.

        Usage:
          config.launcher.bluetooth {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Set the launcher functions
    launcher.dmenu = launcherDmenuCmd;
    launcher.show = launcherShowCmd;
    launcher.wifi = launcherWifiCmd;
    launcher.bluetooth = launcherBluetoothCmd;
  };
}
