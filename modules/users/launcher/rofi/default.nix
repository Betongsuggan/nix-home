{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

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
      default = "urxvt";
      description = "Terminal to use with rofi";
    };

    theme = mkOption {
      type = types.str;
      default = "gruvbox-dark-soft";
      description = "Rofi theme to use";
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
    launcher.rofi.wifi = wifiControl;
    launcher.rofi.bluetooth = bluetoothControl;

    programs.rofi = {
      enable = true;
      terminal = cfg.rofi.terminal;
      theme = cfg.rofi.theme;
    };
  };
}
