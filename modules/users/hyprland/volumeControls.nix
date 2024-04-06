{ config, lib, pkgs, ... }:
let
  volumeChanges = pkgs.writeShellScriptBin "volume-change" ''
    #!/bin/bash
    
    # Arbitrary but unique message tag
    msgTag="volumeChange"
    
    # Change the volume using alsa(might differ if you use pulseaudio)
    # amixer -c 0 set Master "$@" > /dev/null
    
    # Query amixer for the current volume and whether or not the speaker is muted
    volume="$(${pkgs.pamixer}/bin/pamixer --get-volume-human | sed 's/%//g')"

    if [[ "$volume" == "0" || "$volume" == "muted" ]]; then
        # Show the sound muted notification
        dunstify -a "changeVolume" -u low -i audio-volume-muted -h string:x-dunst-stack-tag:$msgTag "Volume muted" 
    else
        # Show the volume notification
        dunstify -a "changeVolume" -u low -i audio-volume-high -h string:x-dunst-stack-tag:$msgTag \
        -h int:value:"$volume" "Volume: ${volume}%"
    fi
    
    # Play the volume changed sound
    canberra-gtk-play -i audio-volume-change -d "changeVolume"
  '';
in
{
  volumeChange = volumeChanges;
}
