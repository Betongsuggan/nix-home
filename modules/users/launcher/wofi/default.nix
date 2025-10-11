{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

  # WiFi control script using wofi
  wifiControl = import ./launchers/wifiControls.nix { inherit config pkgs; };

  # Bluetooth control script using wofi
  # TODO: Implement bluetooth control for wofi
  bluetoothControl = pkgs.writeShellScriptBin "bluetooth-control" ''
    #!/usr/bin/env bash
    echo "Bluetooth control not yet implemented for wofi" >&2
    exit 1
  '';

in {
  options.launcher.wofi = {
    settings = mkOption {
      type = types.attrs;
      default = {
        allow_images = true;
        image_size = 15;
      };
      description = "Additional wofi configuration (merged with defaults)";
    };

    style = mkOption {
      type = types.str;
      default = "";
      description = "Custom wofi CSS styling";
    };

    wifi = mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      description = "WiFi control package for wofi";
    };

    bluetooth = mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      description = "Bluetooth control package for wofi";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "wofi") {
    launcher.wofi.wifi = wifiControl;
    launcher.wofi.bluetooth = bluetoothControl;

    home.packages = with pkgs; [
      wofi
      wofi-emoji
      wifiControl
      bluetoothControl
    ];

    programs.wofi = {
      enable = true;
      settings = cfg.wofi.settings;
      style = if cfg.wofi.style != "" then cfg.wofi.style else ''
        window {
          font-size: 18px;
          border-radius: ${config.theme.cornerRadius};
          border-color: ${config.theme.colors.orange-light};
          background-color: ${config.theme.colors.background-dark};
          color: ${config.theme.colors.text-light};
        }

        #entry {
          padding: 0.50em;
        }

        #entry:selected {
          background-color: ${config.theme.colors.red-dark};
        }

        #text:selected {
          color: ${config.theme.colors.text-light};
        }

        #input {
          background-color: ${config.theme.colors.background-light};
          color: ${config.theme.colors.text-light};
          padding: 0.50em;
        }

        image {
          margin-left: 0.25em;
          margin-right: 0.25em;
        }
      '';
    };
  };
}
