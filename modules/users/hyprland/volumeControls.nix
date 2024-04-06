{ pkgs, ... }:
let
  volumeControl = pkgs.writeShellScriptBin "volume-control" ''
    #!/usr/bin/env bash
    
    # Arbitrary but unique message tag
    tag="volumeControl"
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
        ${pkgs.dunst}/bin/dunstify -u low -i audio-volume-muted -h string:x-dunst-stack-tag:$tag -a "$sink" "Muted"
    else
        # Show the volume notification
        ${pkgs.dunst}/bin/dunstify -u low -i audio-volume-high -h string:x-dunst-stack-tag:$tag -h int:value:"$volume" -a "$sink" ""
    fi
  '';
in
{
  inherit volumeControl;
}
