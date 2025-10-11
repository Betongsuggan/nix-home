{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

  # Helper to build wofi dmenu command
  buildWofiDmenuCmd = {
    prompt ? null
    , password ? false
    , insensitive ? false
    , multiSelect ? false
    , allowImages ? null
    , additionalArgs ? []
  }: let
    promptFlag = optionalString (prompt != null) "--prompt \"${prompt}\"";
    passwordFlag = optionalString password "--password";
    insensitiveFlag = optionalString insensitive "--insensitive";
    multiSelectFlag = optionalString multiSelect "--multi-select";
    allowImagesFlag = optionalString (allowImages != null) "--allow-images=${if allowImages then "true" else "false"}";
    additionalArgsStr = concatStringsSep " " additionalArgs;
  in "${pkgs.wofi}/bin/wofi --dmenu ${promptFlag} ${passwordFlag} ${insensitiveFlag} ${multiSelectFlag} ${allowImagesFlag} ${additionalArgsStr}";

  # Helper to build wofi show command (application launcher)
  buildWofiShowCmd = {
    mode ? "drun"  # drun, run, dmenu
    , additionalArgs ? []
  }: let
    # Map generic modes to wofi-specific modes
    wofiMode = if mode == "applications" then "drun"
               else if mode == "symbols" then "drun"  # wofi-emoji handled separately
               else mode;
    additionalArgsStr = concatStringsSep " " additionalArgs;
  in "${pkgs.wofi}/bin/wofi --show ${wofiMode} ${additionalArgsStr}";

  # Helper to build rofi dmenu command
  buildRofiDmenuCmd = {
    prompt ? null
    , password ? false
    , insensitive ? false
    , multiSelect ? false
    , allowImages ? null
    , additionalArgs ? []
  }: let
    promptFlag = optionalString (prompt != null) "-p \"${prompt}\"";
    passwordFlag = optionalString password "-password";
    insensitiveFlag = optionalString insensitive "-i";
    multiSelectFlag = optionalString multiSelect "-multi-select";
    additionalArgsStr = concatStringsSep " " additionalArgs;
  in "${pkgs.rofi}/bin/rofi -dmenu ${promptFlag} ${passwordFlag} ${insensitiveFlag} ${multiSelectFlag} ${additionalArgsStr}";

  # Helper to build rofi show command
  buildRofiShowCmd = {
    mode ? "drun"
    , additionalArgs ? []
  }: let
    # Map generic modes to rofi-specific modes
    rofiMode = if mode == "applications" then "drun"
               else if mode == "symbols" then "emoji"
               else mode;
    additionalArgsStr = concatStringsSep " " additionalArgs;
  in "${pkgs.rofi}/bin/rofi -show ${rofiMode} ${additionalArgsStr}";

  # Helper to build walker dmenu command
  buildWalkerDmenuCmd = {
    prompt ? null
    , password ? false
    , insensitive ? false
    , multiSelect ? false
    , allowImages ? null
    , additionalArgs ? []
  }: let
    # Walker uses dmenu mode via the dmenu builtin
    additionalArgsStr = concatStringsSep " " additionalArgs;
  in "${pkgs.walker}/bin/walker -m dmenu ${additionalArgsStr}";

  # Helper to build walker show command
  buildWalkerShowCmd = {
    mode ? "applications"  # applications, runner, websearch, etc.
    , additionalArgs ? []
  }: let
    additionalArgsStr = concatStringsSep " " additionalArgs;
  in "${pkgs.walker}/bin/walker -m ${mode} ${additionalArgsStr}";

  # Main launcher dmenu function - delegates to backend
  launcherDmenuCmd = args:
    if cfg.backend == "wofi" then buildWofiDmenuCmd args
    else if cfg.backend == "rofi" then buildRofiDmenuCmd args
    else if cfg.backend == "walker" then buildWalkerDmenuCmd args
    else throw "Unsupported launcher backend: ${cfg.backend}";

  # Main launcher show function - delegates to backend
  launcherShowCmd = args:
    if cfg.backend == "wofi" then buildWofiShowCmd args
    else if cfg.backend == "rofi" then buildRofiShowCmd args
    else if cfg.backend == "walker" then buildWalkerShowCmd args
    else throw "Unsupported launcher backend: ${cfg.backend}";

  # WiFi launcher - delegates to backend-specific implementation
  launcherWifiCmd = {
    additionalArgs ? []
  }:
    if cfg.backend == "wofi" then "${cfg.wofi.wifi}/bin/wifi-control"
    else if cfg.backend == "rofi" then "${cfg.rofi.wifi}/bin/wifi-control"
    else if cfg.backend == "walker" then "${pkgs.unstable.iwmenu}/bin/iwmenu --launcher walker --spaces 2 ${concatStringsSep " " additionalArgs}"
    else throw "Unsupported launcher backend: ${cfg.backend}";

  # Bluetooth launcher - delegates to backend-specific implementation
  launcherBluetoothCmd = {
    additionalArgs ? []
  }:
    if cfg.backend == "wofi" then "${cfg.wofi.bluetooth}/bin/bluetooth-control"
    else if cfg.backend == "rofi" then "${cfg.rofi.bluetooth}/bin/bluetooth-control"
    else if cfg.backend == "walker" then "${pkgs.unstable.bzmenu}/bin/bzmenu --launcher walker --spaces 2 ${concatStringsSep " " additionalArgs}"
    else throw "Unsupported launcher backend: ${cfg.backend}";

in {
  imports = [
    ./wofi
    ./rofi
    ./walker
  ];

  options.launcher = {
    enable = mkEnableOption "launcher system";

    backend = mkOption {
      type = types.enum [ "wofi" "rofi" "walker" ];
      default = "walker";
      description = "Which launcher to use";
    };

    # Expose the dmenu function for other modules to use
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

    # Expose the show function for launching applications
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

    # Expose WiFi launcher
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

    # Expose Bluetooth launcher
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
