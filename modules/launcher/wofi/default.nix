{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.launcher;

  # Helper to build wofi dmenu command
  buildDmenuCmd =
    {
      prompt ? null,
      password ? false,
      insensitive ? false,
      multiSelect ? false,
      allowImages ? null,
      additionalArgs ? [ ],
    }:
    let
      promptFlag = optionalString (prompt != null) ''--prompt "${prompt}"'';
      passwordFlag = optionalString password "--password";
      insensitiveFlag = optionalString insensitive "--insensitive";
      multiSelectFlag = optionalString multiSelect "--multi-select";
      allowImagesFlag =
        optionalString (allowImages != null)
          "--allow-images=${if allowImages then "true" else "false"}";
      additionalArgsStr = concatStringsSep " " additionalArgs;
    in
    "${pkgs.wofi}/bin/wofi --dmenu ${promptFlag} ${passwordFlag} ${insensitiveFlag} ${multiSelectFlag} ${allowImagesFlag} ${additionalArgsStr}";

  # Helper to build wofi show command (application launcher)
  buildShowCmd =
    {
      mode ? "drun", # drun, run, dmenu
      additionalArgs ? [ ],
    }:
    let
      # Map generic modes to wofi-specific modes
      wofiMode =
        if mode == "applications" then
          "drun"
        else if mode == "symbols" then
          "drun" # wofi-emoji handled separately
        else
          mode;
      additionalArgsStr = concatStringsSep " " additionalArgs;
    in
    "${pkgs.wofi}/bin/wofi --show ${wofiMode} ${additionalArgsStr}";

  # WiFi control script using wofi
  wifiControl = import ./launchers/wifiControls.nix { inherit config pkgs; };

  # Bluetooth control script using wofi
  # TODO: Implement bluetooth control for wofi
  bluetoothControl = pkgs.writeShellScriptBin "bluetooth-control" ''
    #!/usr/bin/env bash
    echo "Bluetooth control not yet implemented for wofi" >&2
    exit 1
  '';

in
{
  options.my.launcher.wofi = {
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

    buildDmenuCmd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = "Function to build wofi dmenu commands";
    };

    buildShowCmd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = "Function to build wofi show commands";
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
    my.launcher.wofi.buildDmenuCmd = buildDmenuCmd;
    my.launcher.wofi.buildShowCmd = buildShowCmd;
    my.launcher.wofi.wifi = wifiControl;
    my.launcher.wofi.bluetooth = bluetoothControl;

    home.packages = with pkgs; [
      wofi
      wofi-emoji
      wifiControl
      bluetoothControl
    ];

    programs.wofi = {
      enable = true;
      settings = cfg.wofi.settings;
      style =
        if cfg.wofi.style != "" then
          cfg.wofi.style
        else
          ''
            window {
              font-size: 18px;
              border-radius: ${toString config.my.theming.cornerRadius}px;
              border-color: ${config.my.theming.colors.bright.yellow};
              background-color: ${config.my.theming.colors.primary.background};
              color: ${config.my.theming.colors.primary.foreground};
            }

            #entry {
              padding: 0.50em;
            }

            #entry:selected {
              background-color: ${config.my.theming.colors.normal.red};
            }

            #text:selected {
              color: ${config.my.theming.colors.primary.foreground};
            }

            #input {
              background-color: ${config.my.theming.colors.bright.black};
              color: ${config.my.theming.colors.primary.foreground};
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
