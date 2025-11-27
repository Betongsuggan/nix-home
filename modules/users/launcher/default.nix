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
    else if cfg.backend == "vicinae" then
      cfg.vicinae.buildDmenuCmd args
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
    else if cfg.backend == "vicinae" then
      cfg.vicinae.buildShowCmd args
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
    else if cfg.backend == "vicinae" then
      "${pkgs.vicinae}/bin/vicinae deeplink 'vicinae://extensions/dagimg-dot/wifi-commander/scan-wifi' ${
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
    else if cfg.backend == "vicinae" then
      "${pkgs.vicinae}/bin/vicinae deeplink 'vicinae://extensions/Gelei/bluetooth/devices' ${
        concatStringsSep " " additionalArgs
      }"
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

  # Audio output launcher - delegates to backend-specific implementation
  launcherAudioOutputCmd = { additionalArgs ? [ ] }:
    if cfg.backend == "wofi" then
      throw "Audio menu not yet implemented for wofi"
    else if cfg.backend == "rofi" then
      throw "Audio menu not yet implemented for rofi"
    else if cfg.backend == "walker" then
      "${pkgs.audiomenu}/bin/audiomenu sink --launcher walker ${
        concatStringsSep " " additionalArgs
      }"
    else if cfg.backend == "vicinae" then
      "${pkgs.audiomenu}/bin/audiomenu sink --launcher vicinae ${
        concatStringsSep " " additionalArgs
      }"
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

  # Audio input launcher - delegates to backend-specific implementation
  launcherAudioInputCmd = { additionalArgs ? [ ] }:
    if cfg.backend == "wofi" then
      throw "Audio menu not yet implemented for wofi"
    else if cfg.backend == "rofi" then
      throw "Audio menu not yet implemented for rofi"
    else if cfg.backend == "walker" then
      "${pkgs.audiomenu}/bin/audiomenu source --launcher walker ${
        concatStringsSep " " additionalArgs
      }"
    else if cfg.backend == "vicinae" then
      "${pkgs.audiomenu}/bin/audiomenu source --launcher vicinae ${
        concatStringsSep " " additionalArgs
      }"
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

  # Monitor launcher - delegates to backend-specific implementation
  launcherMonitorCmd = { additionalArgs ? [ ] }:
    if cfg.backend == "wofi" then
      throw "Monitor menu not yet implemented for wofi"
    else if cfg.backend == "rofi" then
      throw "Monitor menu not yet implemented for rofi"
    else if cfg.backend == "walker" then
      "${pkgs.monitormenu}/bin/monitormenu --launcher walker ${
        concatStringsSep " " additionalArgs
      }"
    else if cfg.backend == "vicinae" then
      "${pkgs.vicinae}/bin/vicinae deeplink 'vicinae://extensions/birgerrydback/hyprland-monitors/list-monitors' ${
        concatStringsSep " " additionalArgs
      }"
      #"${pkgs.monitormenu}/bin/monitormenu --launcher vicinae ${
      #      concatStringsSep " " additionalArgs
      #   }"
    else
      throw "Unsupported launcher backend: ${cfg.backend}";

in {
  imports = [ ./wofi ./rofi ./walker ./vicinae ];

  options.launcher = {
    enable = mkEnableOption "launcher system";

    backend = mkOption {
      type = types.enum [ "wofi" "rofi" "walker" "vicinae" ];
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

    audioOutput = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate audio output device selection launcher.

        Usage:
          config.launcher.audioOutput {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    audioInput = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate audio input device selection launcher.

        Usage:
          config.launcher.audioInput {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    monitor = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate monitor configuration launcher.

        Usage:
          config.launcher.monitor {
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
    launcher.audioOutput = launcherAudioOutputCmd;
    launcher.audioInput = launcherAudioInputCmd;
    launcher.monitor = launcherMonitorCmd;
  };
}
