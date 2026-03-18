{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

  # Helper to build rofi dmenu command
  buildDmenuCmd = { prompt ? null, password ? false, insensitive ? false
    , multiSelect ? false, allowImages ? null, additionalArgs ? [ ] }:
    let
      promptFlag = optionalString (prompt != null) ''-p "${prompt}"'';
      passwordFlag = optionalString password "-password";
      insensitiveFlag = optionalString insensitive "-i";
      multiSelectFlag = optionalString multiSelect "-multi-select";
      additionalArgsStr = concatStringsSep " " additionalArgs;
    in "${pkgs.rofi}/bin/rofi -dmenu ${promptFlag} ${passwordFlag} ${insensitiveFlag} ${multiSelectFlag} ${additionalArgsStr}";

  # Helper to build rofi show command
  buildShowCmd = { mode ? "drun", additionalArgs ? [ ] }:
    let
      # Map generic modes to rofi-specific modes
      rofiMode = if mode == "applications" then
        "drun"
      else if mode == "symbols" then
        "emoji"
      else
        mode;
      additionalArgsStr = concatStringsSep " " additionalArgs;
    in "${pkgs.rofi}/bin/rofi -show ${rofiMode} ${additionalArgsStr}";

  # WiFi control script using rofi
  # TODO: Port wifi-control to use rofi
  wifiControl = pkgs.writeShellScriptBin "wifi-control" ''
    #!/usr/bin/env bash
    echo "WiFi control not yet implemented for rofi" >&2
    exit 1
  '';

  # Bluetooth control script using rofi
  # TODO: Implement bluetooth control for rofi
  bluetoothControl = pkgs.writeShellScriptBin "bluetooth-control" ''
    #!/usr/bin/env bash
    echo "Bluetooth control not yet implemented for rofi" >&2
    exit 1
  '';

in {
  options.launcher.rofi = {
    terminal = mkOption {
      type = types.str;
      default = config.terminal.command;
      description = "Terminal to use with rofi (defaults to config.terminal.command)";
    };

    theme = mkOption {
      type = types.str;
      default = "gruvbox-dark-soft";
      description = "Rofi theme to use";
    };

    buildDmenuCmd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = "Function to build rofi dmenu commands";
    };

    buildShowCmd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = "Function to build rofi show commands";
    };

    wifi = mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      description = "WiFi control package for rofi";
    };

    bluetooth = mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      description = "Bluetooth control package for rofi";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "rofi") {
    launcher.rofi.buildDmenuCmd = buildDmenuCmd;
    launcher.rofi.buildShowCmd = buildShowCmd;
    launcher.rofi.wifi = wifiControl;
    launcher.rofi.bluetooth = bluetoothControl;

    programs.rofi = {
      enable = true;
      terminal = cfg.rofi.terminal;
      theme = cfg.rofi.theme;
    };
  };
}
