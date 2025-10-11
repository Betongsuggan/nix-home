{ config, pkgs, ... }:
let
  # Build notification commands using the notifications module
  notifyMuted = config.notifications.send {
    urgency = "low";
    icon = "audio-volume-muted";
    appName = "\$sink";
    summary = "Muted";
    hints = {
      "string:x-dunst-stack-tag" = "volumeControl";
    };
  };

  notifyVolume = config.notifications.send {
    urgency = "low";
    icon = "audio-volume-high";
    appName = "\$sink";
    summary = "";
    hints = {
      "string:x-dunst-stack-tag" = "volumeControl";
      "int:value" = "\$volume";
    };
  };

  volumeControl = pkgs.writeShellScriptBin "volume-control" ''
    #!/usr/bin/env bash

    while getopts i:d:ms option
    do
        echo "$option"
        case "''${option}"
            in
            i) ${pkgs.pamixer}/bin/pamixer -i ''${OPTARG};;
            d) ${pkgs.pamixer}/bin/pamixer -d ''${OPTARG};;
            m) ${pkgs.pamixer}/bin/pamixer -t ;;
        esac
    done

    volume="$(${pkgs.pamixer}/bin/pamixer --get-volume-human | sed 's/%//g')"
    sink="$(${pkgs.pamixer}/bin/pamixer --get-default-sink |  awk -F '"' '{print $4}' | awk 'NF')"

    if [[ "$volume" == "0" || "$volume" == "muted" ]]; then
        # Show the sound muted notification
        ${notifyMuted}
    else
        # Show the volume notification
        ${notifyVolume}
    fi
  '';
in
volumeControl
