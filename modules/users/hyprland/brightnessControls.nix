{ pkgs, ... }:
let
  brightnessControl = pkgs.writeShellScriptBin "brightness-control" ''
    #!/usr/bin/env bash
    
    # Arbitrary but unique message tag
    tag="brightnessControl"
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

    ${pkgs.dunst}/bin/dunstify -u low -i whitebalance -h string:x-dunst-stack-tag:$tag -h int:value:$brightness -a "Brightness" "" 
  '';
in
brightnessControl
