{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.battery-monitor;

  # Notification commands using the notifications module
  notifyChargerConnected = config.notifications.send {
    urgency = "low";
    icon = "battery-charging";
    appName = "Battery Monitor";
    summary = "Charger Connected";
    body = "Battery: \$PERCENT%";
  };

  notifyChargerDisconnected = config.notifications.send {
    urgency = "normal";
    icon = "battery-discharging";
    appName = "Battery Monitor";
    summary = "Charger Disconnected";
    body = "Battery: \$PERCENT%";
  };

  notifyCritical = config.notifications.send {
    urgency = "critical";
    icon = "battery-caution";
    appName = "Battery Monitor";
    summary = "Critical Battery Level!";
    body = "Battery at \$PERCENT%\\nPlease connect charger immediately!";
  };

  notifyLow = config.notifications.send {
    urgency = "normal";
    icon = "battery-low";
    appName = "Battery Monitor";
    summary = "Low Battery";
    body = "Battery at \$PERCENT%\\nConsider connecting charger soon.";
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

    # Extract battery percentage and state
    PERCENT=$(echo "$BATTERY_INFO" | ${pkgs.gnugrep}/bin/grep 'percentage' | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.gnused}/bin/sed 's/%//')
    STATE=$(echo "$BATTERY_INFO" | ${pkgs.gnugrep}/bin/grep 'state' | ${pkgs.gawk}/bin/awk '{print $2}')

    # Read previous state
    PREV_STATE=""
    NOTIFIED_LOW=false
    NOTIFIED_CRITICAL=false

    if [ -f "$STATE_FILE" ]; then
      source "$STATE_FILE"
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
    cat > "$STATE_FILE" <<EOF
    PREV_STATE="$STATE"
    NOTIFIED_LOW=$NOTIFIED_LOW
    NOTIFIED_CRITICAL=$NOTIFIED_CRITICAL
    EOF
  '';

in {
  options.battery-monitor = {
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

    checkInterval = mkOption {
      type = types.str;
      default = "1min";
      description = "How often to check battery status (systemd time format)";
    };
  };

  config = mkIf cfg.enable {
    # Auto-enable notifications when battery-monitor is enabled
    notifications.enable = mkDefault true;

    home.packages = [ batteryMonitorScript ];

    # Systemd service to check battery
    systemd.user.services.battery-monitor = {
      Unit = {
        Description = "Battery Monitor Check";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${batteryMonitorScript}/bin/battery-monitor-check";
      };
    };

    # Systemd timer to run battery check periodically
    systemd.user.timers.battery-monitor = {
      Unit = {
        Description = "Battery Monitor Timer";
      };

      Timer = {
        OnBootSec = "30s";
        OnUnitActiveSec = cfg.checkInterval;
        Unit = "battery-monitor.service";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}