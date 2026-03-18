{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.controls.volume;
  
  # Build notification commands using the notifications module
  notifyMuted = optionalString cfg.notifications (config.notifications.send {
    urgency = "low";
    icon = "audio-volume-muted";
    appName = "\$sink";
    summary = "Muted";
    hints = {
      "string:x-dunst-stack-tag" = "volumeControl";
    };
  });

  notifyVolume = optionalString cfg.notifications (config.notifications.send {
    urgency = "low";
    icon = "audio-volume-high";
    appName = "\$sink";
    summary = "";
    hints = {
      "string:x-dunst-stack-tag" = "volumeControl";
      "int:value" = "\$volume";
    };
  });

  volumeBackend = if cfg.backend == "pamixer" then pkgs.pamixer else pkgs.pulseaudio;
  
  volumeCommands = {
    pamixer = {
      increase = "${volumeBackend}/bin/pamixer -i";
      decrease = "${volumeBackend}/bin/pamixer -d";
      toggle = "${volumeBackend}/bin/pamixer -t";
      getVolume = "${volumeBackend}/bin/pamixer --get-volume-human | sed 's/%//g'";
      getSink = "${volumeBackend}/bin/pamixer --get-default-sink | awk -F '\"' '{print $4}' | awk 'NF'";
    };
    pactl = {
      increase = "${volumeBackend}/bin/pactl set-sink-volume @DEFAULT_SINK@ +";
      decrease = "${volumeBackend}/bin/pactl set-sink-volume @DEFAULT_SINK@ -";
      toggle = "${volumeBackend}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
      getVolume = "${volumeBackend}/bin/pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -1";
      getSink = "${volumeBackend}/bin/pactl get-default-sink";
    };
  };

  cmds = volumeCommands.${cfg.backend};
  
  volumeControl = pkgs.writeShellScriptBin "volume-control" ''
    #!/usr/bin/env bash

    while getopts i:d:ms option
    do
        echo "$option"
        case "''${option}"
            in
            i) ${cmds.increase} ''${OPTARG};;
            d) ${cmds.decrease} ''${OPTARG};;
            m) ${cmds.toggle};;
        esac
    done

    volume="$(${cmds.getVolume})"
    sink="$(${cmds.getSink})"

    if [[ "$volume" == "0" || "$volume" == "muted" ]]; then
        # Show the sound muted notification
        ${notifyMuted}
    else
        # Show the volume notification
        ${notifyVolume}
    fi
  '';
in
{
  config = mkIf (config.controls.enable && cfg.enable) {
    home.packages = [
      volumeControl
      volumeBackend
    ];
  };
}