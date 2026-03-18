{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.controls.mediaPlayer;
  
  # Build notification command using the notifications module
  notifyMedia = optionalString cfg.notifications (config.notifications.send {
    urgency = "low";
    icon = "\$icon";
    appName = "\$artist";
    summary = "\$title";
    hints = {
      "string:x-dunst-stack-tag" = "mediaPlayer";
    };
  });

  mediaPlayerControl = pkgs.writeShellScriptBin "media-player" ''
    #!/usr/bin/env bash

    # Check if any player is available
    status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)

    if [ -z "$status" ]; then
      # No player found
      icon="media-playback-stop"
      artist="Media Player"
      title="No player active"
      ${notifyMedia}
      exit 0
    fi

    # Set icon based on status
    case "$status" in
      Playing)
        icon="media-playback-playing"
        ;;
      Paused)
        icon="media-playback-paused"
        ;;
      Stopped)
        icon="media-playback-stop"
        ;;
      *)
        icon="media-playback-paused"
        ;;
    esac

    case $1 in
      play)
        ${pkgs.playerctl}/bin/playerctl play-pause 2>/dev/null
        # Update status after play-pause
        new_status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
        if [ "$new_status" == "Playing" ]; then
          icon="media-playback-start"
        else
          icon="media-playback-pause"
        fi
        ;;
      next)
        ${pkgs.playerctl}/bin/playerctl next 2>/dev/null
        icon="media-skip-forward"
        ;;
      previous)
        ${pkgs.playerctl}/bin/playerctl previous 2>/dev/null
        icon="media-skip-backward"
        ;;
      status)
        # Just show current status without changing anything
        ;;
    esac

    artist=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{ artist }}' 2>/dev/null || echo "Unknown Artist")
    title=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{ title }}' 2>/dev/null || echo "Unknown Title")

    # Only send notification if we have valid data
    if [ -n "$artist" ] && [ -n "$title" ]; then
      ${notifyMedia}
    fi
  '';
in
{
  config = mkIf (config.controls.enable && cfg.enable) {
    home.packages = [
      mediaPlayerControl
      pkgs.playerctl
    ];
  };
}