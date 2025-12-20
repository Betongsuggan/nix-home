{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.game-streaming.server;

  # Script to set monitor resolution to match Moonlight client
  set-streaming-resolution =
    pkgs.writeShellScriptBin "set-streaming-resolution" ''
      #!/usr/bin/env bash
      LOG="/tmp/streaming-resolution.log"
      echo "$(date): set-streaming-resolution started" >> "$LOG"

      MONITOR="${cfg.display}"
      WIDTH="$SUNSHINE_CLIENT_WIDTH"
      HEIGHT="$SUNSHINE_CLIENT_HEIGHT"
      FPS="$SUNSHINE_CLIENT_FPS"

      echo "  Monitor: $MONITOR" >> "$LOG"
      echo "  Target: ''${WIDTH}x''${HEIGHT}@''${FPS}" >> "$LOG"

      # Save original resolution for undo
      ${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name=="'"$MONITOR"'") | "\(.width)x\(.height)@\(.refreshRate)"' > /tmp/original-resolution
      ORIG=$(cat /tmp/original-resolution)
      echo "  Original resolution: $ORIG" >> "$LOG"

      # Set new resolution
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "$MONITOR,''${WIDTH}x''${HEIGHT}@''${FPS},0x0,1"
      echo "  Resolution set to ''${WIDTH}x''${HEIGHT}@''${FPS}" >> "$LOG"

      echo "Resolution set to ''${WIDTH}x''${HEIGHT}@''${FPS}"
      sleep 2
    '';

  # Script to restore original resolution
  restore-resolution = pkgs.writeShellScriptBin "restore-resolution" ''
    #!/usr/bin/env bash
    LOG="/tmp/streaming-resolution.log"
    echo "$(date): restore-resolution started" >> "$LOG"

    MONITOR="${cfg.display}"

    if [[ -f /tmp/original-resolution ]]; then
      ORIG=$(cat /tmp/original-resolution)
      echo "  Restoring to: $ORIG" >> "$LOG"
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "$MONITOR,$ORIG,0x0,1"
      rm /tmp/original-resolution
      echo "Resolution restored to $ORIG"
    else
      echo "  No original resolution saved" >> "$LOG"
    fi
  '';

in {
  options.game-streaming = {
    server = {
      enable = mkOption {
        description = "Enable game streaming server";
        type = types.bool;
        default = false;
      };
      display = mkOption {
        description = "Display connector to use for streaming (e.g., 'DP-2')";
        type = types.str;
        default = "DP-2";
        example = "DP-2";
      };
    };
    client = {
      enable = mkOption {
        description = "Enable game streaming client";
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkMerge [
    # Server configuration
    (mkIf config.game-streaming.server.enable {
      # Sunshine requires uinput for virtual input devices (keyboard, mouse, gamepad injection)
      boot.kernelModules = [ "uinput" ];
      hardware.uinput.enable = true;

      # Create uinput group and set proper permissions on /dev/uinput
      users.groups.uinput = { };
      services.udev.extraRules = ''
        KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
      '';

      services.sunshine = {
        enable = true;
        autoStart = true;
        openFirewall = true;
        capSysAdmin = false;
        settings = {
          sunshine_name = "betongsuggan station";
          capture = "wlr";
          output_name = cfg.display;
        };
        applications = {
          apps = [{
            name = "Set Streaming Resolution";
            cmd = "${set-streaming-resolution}/bin/set-streaming-resolution";
            prep-cmd = [{
              do = "";
              undo = "${restore-resolution}/bin/restore-resolution";
            }];
            auto-detach = "true";
          }];
        };
      };

      environment.systemPackages = [
        set-streaming-resolution
        restore-resolution
        pkgs.jq
      ];
    })

    # Client configuration
    (mkIf config.game-streaming.client.enable {
      environment.systemPackages = [ pkgs.moonlight-qt ];
    })
  ];
}
