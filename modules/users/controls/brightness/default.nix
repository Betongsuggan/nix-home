{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.controls.brightness;
  
  # Build notification command using the notifications module
  notifyBrightness = optionalString cfg.notifications (config.notifications.send {
    urgency = "low";
    icon = "whitebalance";
    appName = "Brightness";
    summary = "";
    hints = {
      "string:x-dunst-stack-tag" = "brightnessControl";
      "int:value" = "\$brightness";
    };
  });

  brightnessBackend = if cfg.backend == "light" then pkgs.light else pkgs.brightnessctl;
  
  brightnessCommands = {
    light = {
      increase = "${brightnessBackend}/bin/light -A";
      decrease = "${brightnessBackend}/bin/light -U";
      get = "${brightnessBackend}/bin/light";
    };
    brightnessctl = {
      increase = "${brightnessBackend}/bin/brightnessctl set +";
      decrease = "${brightnessBackend}/bin/brightnessctl set ";
      get = "${brightnessBackend}/bin/brightnessctl get";
    };
  };

  cmds = brightnessCommands.${cfg.backend};
  
  brightnessControl = pkgs.writeShellScriptBin "brightness-control" ''
    #!/usr/bin/env bash

    while getopts i:d:ms option
    do
        echo "$option"
        case "''${option}"
            in
            i) ${cmds.increase} ''${OPTARG};;
            d) ${cmds.decrease} ''${OPTARG};;
        esac
    done

    ${if cfg.backend == "light" then ''
      brightness="$(${cmds.get} | sed 's/\..*//')"
    '' else ''
      brightness="$(${cmds.get})"
    ''}

    ${notifyBrightness}
  '';
in
{
  config = mkIf (config.controls.enable && cfg.enable) {
    home.packages = [
      brightnessControl
      brightnessBackend
    ];
  };
}