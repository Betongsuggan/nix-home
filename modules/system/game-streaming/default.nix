{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.game-streaming.server;

  # Script to prepare streaming session
  # Creates virtual monitor, disables physical monitors, and sets up Steam
  prepare-streaming-session =
    pkgs.writeShellScriptBin "prepare-streaming-session" ''
      #!/usr/bin/env bash
      LOG="/tmp/streaming-session.log"
      WORKSPACE="${toString cfg.workspace}"
      VIRTUAL_MON="${cfg.display}"

      # Use Sunshine's environment variables for resolution, with defaults
      WIDTH=''${SUNSHINE_CLIENT_WIDTH:-1920}
      HEIGHT=''${SUNSHINE_CLIENT_HEIGHT:-1080}
      FPS=''${SUNSHINE_CLIENT_FPS:-60}

      echo "$(date): prepare-streaming-session started" >> "$LOG"
      echo "  Virtual monitor: $VIRTUAL_MON" >> "$LOG"
      echo "  Resolution: ''${WIDTH}x''${HEIGHT}@''${FPS}" >> "$LOG"
      echo "  Target workspace: $WORKSPACE" >> "$LOG"

      # Save current monitor config for restoration
      ${pkgs.hyprland}/bin/hyprctl monitors -j > /tmp/monitors-backup.json
      echo "  Saved monitor config to /tmp/monitors-backup.json" >> "$LOG"

      # Create virtual monitor for streaming
      ${pkgs.hyprland}/bin/hyprctl output create headless "$VIRTUAL_MON"
      echo "  Created headless monitor: $VIRTUAL_MON" >> "$LOG"

      # Disable physical monitors (get list from backup, exclude the virtual one)
      PHYSICAL_MONITORS=$(${pkgs.jq}/bin/jq -r '.[].name' /tmp/monitors-backup.json | grep -v "^$VIRTUAL_MON$")
      DISABLE_CMD=""
      for mon in $PHYSICAL_MONITORS; do
        DISABLE_CMD="$DISABLE_CMD keyword monitor $mon,disable ;"
        echo "  Disabling monitor: $mon" >> "$LOG"
      done
      ${pkgs.hyprland}/bin/hyprctl --batch "$DISABLE_CMD"

      # Configure virtual monitor resolution using client's requested settings
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "$VIRTUAL_MON,''${WIDTH}x''${HEIGHT}@''${FPS},0x0,1"
      echo "  Set $VIRTUAL_MON to ''${WIDTH}x''${HEIGHT}@''${FPS}" >> "$LOG"

      # Find Steam Big Picture window
      STEAM_WINDOW=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "steam" and (.title | test("Steam Big Picture Mode|Steam"; "i"))) | .address' | head -1)

      if [[ -n "$STEAM_WINDOW" ]]; then
        echo "  Found Steam window: $STEAM_WINDOW" >> "$LOG"
        ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspacesilent "$WORKSPACE,address:$STEAM_WINDOW"
      else
        echo "  Steam not running, starting..." >> "$LOG"
        ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace $WORKSPACE silent] steam -bigpicture"
        sleep 3
      fi

      # Focus the streaming workspace
      ${pkgs.hyprland}/bin/hyprctl dispatch workspace "$WORKSPACE"
      echo "  Focused workspace $WORKSPACE" >> "$LOG"
      echo "  Streaming session ready" >> "$LOG"
    '';

  # Script to restore monitors after streaming ends
  restore-monitors = pkgs.writeShellScriptBin "restore-monitors" ''
    #!/usr/bin/env bash
    LOG="/tmp/streaming-session.log"
    VIRTUAL_MON="${cfg.display}"

    echo "$(date): restore-monitors started" >> "$LOG"

    # Remove the virtual monitor first
    ${pkgs.hyprland}/bin/hyprctl output remove "$VIRTUAL_MON"
    echo "  Removed virtual monitor: $VIRTUAL_MON" >> "$LOG"

    # Restore physical monitors from backup
    if [[ -f /tmp/monitors-backup.json ]]; then
      # Re-enable each physical monitor with its resolution/refresh but use 'auto' for position
      # This avoids overlap issues from absolute positioning
      ${pkgs.jq}/bin/jq -r '.[] | "\(.name),\(.width)x\(.height)@\(.refreshRate),auto,\(.scale)"' /tmp/monitors-backup.json | while read -r mon_config; do
        MON_NAME=$(echo "$mon_config" | cut -d',' -f1)
        if [[ "$MON_NAME" != "$VIRTUAL_MON" ]]; then
          echo "  Restoring monitor: $mon_config" >> "$LOG"
          ${pkgs.hyprland}/bin/hyprctl keyword monitor "$mon_config"
        fi
      done
      rm /tmp/monitors-backup.json
      echo "  Removed backup file" >> "$LOG"
    else
      echo "  No backup file found" >> "$LOG"
    fi

    # Switch back to workspace 1
    ${pkgs.hyprland}/bin/hyprctl dispatch workspace 1
    echo "  Switched to workspace 1" >> "$LOG"
    echo "  Monitors restored" >> "$LOG"
  '';

in {
  options.game-streaming = {
    server = {
      enable = mkOption {
        description = "Enable game streaming server (Sunshine)";
        type = types.bool;
        default = false;
      };
      display = mkOption {
        description = ''
          Display connector to use for streaming.
          Can be a physical display (e.g., 'DP-1') or a virtual monitor name (e.g., 'SUNSHINE').
        '';
        type = types.str;
        default = "DP-1";
        example = "SUNSHINE";
      };
      workspace = mkOption {
        description = "Workspace number dedicated for streaming";
        type = types.int;
        default = 10;
        example = 10;
      };
      hdr = mkOption {
        description = ''
          Enable HDR streaming support.
          Requires HEVC Main10 or AV1 10-bit encoding capability.
          Note: Virtual monitors may have limited HDR support.
        '';
        type = types.bool;
        default = true;
      };
    };
    client = {
      enable = mkOption {
        description = "Enable game streaming client (Moonlight)";
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
        capSysAdmin = true; # Required for KMS capture, which is more reliable
        settings = {
          sunshine_name = "betongsuggan station";
          output_name = cfg.display;

          # Codec settings: Enable AV1 + HEVC auto-negotiation
          # RX 9070 XT (VCN5) has excellent AV1/HEVC encoding quality
          hevc_mode = 0; # Auto: Main + Main10 for HDR support
          av1_mode = 0;  # Auto: Enable when client supports it (30% better than HEVC)

          # Quality settings optimized for gaming
          qp = 20;           # Lower = better quality (default 28, gaming: 18-22)
          min_threads = 4;   # Better multi-threading for encoding
          fec_percentage = 10; # Reduced from 20 - WiFi 6 has low packet loss

          # Encryption: Disable on LAN for lower latency
          lan_encryption_mode = 0; # No encryption on trusted LAN
          wan_encryption_mode = 1; # Encrypt WAN streams for security
        };
        applications = {
          apps = [{
            name = "Steam Gaming";
            prep-cmd = [{
              do = "${prepare-streaming-session}/bin/prepare-streaming-session";
              undo = "${restore-monitors}/bin/restore-monitors";
            }];
            auto-detach = "true";
          }];
        };
      };

      environment.systemPackages = [
        prepare-streaming-session
        restore-monitors
        pkgs.jq
        pkgs.libva-utils # vainfo for verifying VAAPI encoder capabilities
      ];
    })

    # Client configuration
    (mkIf config.game-streaming.client.enable {
      environment.systemPackages = [ pkgs.moonlight-qt ];
    })
  ];
}
