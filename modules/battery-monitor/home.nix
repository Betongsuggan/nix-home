{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.battery-monitor;

  # Notification commands using the notifications module. All share the
  # battery category's icon and a charge progress bar; severity is signaled
  # by urgency (frame color) alone. The state-specific battery-* icons only
  # exist in Papirus' panel/ context, which dunst's icon path doesn't cover.
  notifyChargerConnected = config.my.notifications.send {
    category = "battery";
    summary = "Charger connected";
    body = "\$PERCENT% · \$POWER_DRAW";
    progress = "\$PERCENT";
  };

  notifyChargerDisconnected = config.my.notifications.send {
    category = "battery";
    summary = "Charger disconnected";
    body = "\$PERCENT% · \$POWER_DRAW";
    progress = "\$PERCENT";
  };

  notifyCritical = config.my.notifications.send {
    category = "battery";
    urgency = "critical";
    summary = "Battery critical";
    body = "\$PERCENT% remaining · connect charger now";
    progress = "\$PERCENT";
  };

  notifyLow = config.my.notifications.send {
    category = "battery";
    urgency = "normal";
    summary = "Battery low";
    body = "\$PERCENT% remaining";
    progress = "\$PERCENT";
  };

  batteryMonitorScript = pkgs.writeShellScriptBin "battery-monitor-check" ''
    #!/usr/bin/env bash

    # State file to track notification status
    STATE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/battery-monitor"
    mkdir -p "$STATE_DIR"
    STATE_FILE="$STATE_DIR/state"

    # Get battery info using upower
    BATTERY_PATH=$(${pkgs.upower}/bin/upower -e | ${pkgs.gnugrep}/bin/grep 'BAT')

    if [ -z "$BATTERY_PATH" ]; then
      # No battery found, exit silently
      exit 0
    fi

    BATTERY_INFO=$(${pkgs.upower}/bin/upower -i "$BATTERY_PATH")

    # Extract battery percentage, state, and energy rate (power draw)
    PERCENT=$(echo "$BATTERY_INFO" | ${pkgs.gnugrep}/bin/grep 'percentage' | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.gnused}/bin/sed 's/%//')
    STATE=$(echo "$BATTERY_INFO" | ${pkgs.gnugrep}/bin/grep 'state' | ${pkgs.gawk}/bin/awk '{print $2}')
    ENERGY_RATE=$(echo "$BATTERY_INFO" | ${pkgs.gnugrep}/bin/grep 'energy-rate' | ${pkgs.gawk}/bin/awk '{print $2, $3}')

    # Format power draw message
    if [ -n "$ENERGY_RATE" ]; then
      POWER_DRAW="$ENERGY_RATE"
    else
      POWER_DRAW="N/A"
    fi

    # Read previous state
    PREV_STATE=""
    NOTIFIED_LOW=false
    NOTIFIED_CRITICAL=false

    if [ -f "$STATE_FILE" ]; then
      source "$STATE_FILE"
    fi

    # Power-source hooks: on the first check of the session and on every
    # AC <-> battery transition
    if [ "$STATE" = "discharging" ]; then SOURCE=battery; else SOURCE=ac; fi
    PREV_SOURCE=""
    case "$PREV_STATE" in
      discharging) PREV_SOURCE=battery ;;
      charging|fully-charged|pending-charge) PREV_SOURCE=ac ;;
    esac
    if [ "$SOURCE" != "$PREV_SOURCE" ]; then
      if [ "$SOURCE" = battery ]; then
        ${concatMapStringsSep "
        " (c: "${c} || true") cfg.onBattery}
        :
      else
        ${concatMapStringsSep "
        " (c: "${c} || true") cfg.onAC}
        :
      fi
    fi

    # If we're charging or fully charged, reset notification flags
    if [ "$STATE" = "charging" ] || [ "$STATE" = "fully-charged" ]; then
      # Notify on charger connect if state changed
      if [ "$PREV_STATE" = "discharging" ]; then
        ${notifyChargerConnected}
      fi

      # Reset flags when charging
      NOTIFIED_LOW=false
      NOTIFIED_CRITICAL=false

    # Only check thresholds when discharging
    elif [ "$STATE" = "discharging" ]; then
      # Notify on charger disconnect if state changed
      if [ "$PREV_STATE" = "charging" ] || [ "$PREV_STATE" = "fully-charged" ]; then
        ${notifyChargerDisconnected}
      fi

      # Critical threshold check
      if [ "$PERCENT" -le "${toString cfg.criticalThreshold}" ] && [ "$NOTIFIED_CRITICAL" = "false" ]; then
        ${notifyCritical}
        NOTIFIED_CRITICAL=true

      # Low threshold check
      elif [ "$PERCENT" -le "${toString cfg.lowThreshold}" ] && [ "$NOTIFIED_LOW" = "false" ]; then
        ${notifyLow}
        NOTIFIED_LOW=true
      fi
    fi

    # Save current state
    printf 'PREV_STATE=%q\nNOTIFIED_LOW=%s\nNOTIFIED_CRITICAL=%s\n' \
      "$STATE" "$NOTIFIED_LOW" "$NOTIFIED_CRITICAL" > "$STATE_FILE"
  '';

in
{
  options.my.battery-monitor = {
    enable = mkEnableOption "Enable battery monitoring with notifications";

    lowThreshold = mkOption {
      type = types.int;
      default = 15;
      description = "Battery percentage threshold for low battery warning";
    };

    criticalThreshold = mkOption {
      type = types.int;
      default = 5;
      description = "Battery percentage threshold for critical battery warning";
    };

    onBattery = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Shell commands run when the session starts on battery or switches to it.";
    };

    onAC = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Shell commands run when the session starts on AC or switches to it.";
    };
  };

  config = mkIf cfg.enable {
    # Auto-enable notifications when battery-monitor is enabled
    my.notifications.enable = mkDefault true;

    home.packages = [ batteryMonitorScript ];

    # Event-driven: re-check whenever upower reports a change of the laptop
    # battery or the charger (peripheral batteries are ignored), instead of
    # polling on a timer. Runs in the graphical session so the power hooks
    # can reach the compositor; the state is reset at start so the hooks are
    # applied once for the current power source.
    systemd.user.services.battery-monitor = {
      Unit = {
        Description = "Battery notifications and power-source hooks";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/battery-monitor/state";
        ExecStart = "${pkgs.writeShellScript "battery-monitor" ''
          ${batteryMonitorScript}/bin/battery-monitor-check
          ${pkgs.upower}/bin/upower --monitor \
            | ${pkgs.gnugrep}/bin/grep --line-buffered -E 'battery_BAT|line_power' \
            | while read -r _; do ${batteryMonitorScript}/bin/battery-monitor-check; done
        ''}";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
