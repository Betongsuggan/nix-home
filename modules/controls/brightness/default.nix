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

  brightnessBackend = pkgs.brightnessctl;

  cmds = {
    increase = "${brightnessBackend}/bin/brightnessctl set";
    decrease = "${brightnessBackend}/bin/brightnessctl set --";
    get = "${brightnessBackend}/bin/brightnessctl get";
  };
  
  brightnessControl = pkgs.writeShellScriptBin "brightness-control" ''
    #!/usr/bin/env bash

    while getopts i:d:ms option
    do
        case "''${option}"
            in
            i) ${cmds.increase} +''${OPTARG};;
            d) ${cmds.decrease} -''${OPTARG};;
        esac
    done

    # Calculate percentage for brightnessctl (raw value / max * 100)
    current="$(${cmds.get})"
    max="$(${brightnessBackend}/bin/brightnessctl max)"
    brightness="$((current * 100 / max))"

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