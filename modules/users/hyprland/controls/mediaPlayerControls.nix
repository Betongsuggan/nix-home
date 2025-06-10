{ pkgs, ... }:
let
  mediaPlayerControl = pkgs.writeShellScriptBin "media-player" ''
    #!/usr/bin/env bash
    tag="mediaPlayer"
    
    icon=""
    status=$(${pkgs.playerctl}/bin/playerctl status)
    if [ "$status" == "Playing" ] 
    then
      icon="media-playback-playing"
    else
      icon="media-playback-paused"
    fi

    case $1 in
      play)
        ${pkgs.playerctl}/bin/playerctl play-pause
        if [ "$status" == "Playing" ] 
        then
          icon="media-playback-pause"
        else
          icon="media-playback-start"
        fi
        ;;
      next)
        ${pkgs.playerctl}/bin/playerctl next
        icon="media-skip-forward"
        ;;
      previous)
        ${pkgs.playerctl}/bin/playerctl previous
        icon="media-skip-backward"
        ;;
    esac
    
    artist=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{ artist }}')
    title=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{ title }}')

   ${pkgs.dunst}/bin/dunstify -u low -i "$icon" -h string:x-dunst-stack-tag:$tag  -a "$artist" "$title"
  '';
in
mediaPlayerControl
