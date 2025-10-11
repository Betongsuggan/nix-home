{ config, pkgs, ... }:
let
  # Build notification command using the notifications module
  notifyBrightness = config.notifications.send {
    urgency = "low";
    icon = "whitebalance";
    appName = "Brightness";
    summary = "";
    hints = {
      "string:x-dunst-stack-tag" = "brightnessControl";
      "int:value" = "\$brightness";
    };
  };

  brightnessControl = pkgs.writeShellScriptBin "brightness-control" ''
    #!/usr/bin/env bash

    while getopts i:d:ms option
    do
        echo "$option"
        case "''${option}"
            in
            i) ${pkgs.light}/bin/light -A ''${OPTARG};;
            d) ${pkgs.light}/bin/light -U ''${OPTARG};;
        esac
    done

    brightness="$(${pkgs.light}/bin/light | sed 's/\..*//')"

    ${notifyBrightness}
  '';
in
brightnessControl
