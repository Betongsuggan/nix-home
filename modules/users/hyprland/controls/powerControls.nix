{ config, pkgs, ... }:
let
  # Build notification commands using the notifications module
  notifySuspend = config.notifications.send {
    urgency = "normal";
    icon = "system-suspend";
    appName = "Power";
    summary = "Suspending system...";
    timeout = 2000;
  };

  notifyHibernate = config.notifications.send {
    urgency = "normal";
    icon = "system-hibernate";
    appName = "Power";
    summary = "Hibernating system...";
    timeout = 2000;
  };

  notifyLogout = config.notifications.send {
    urgency = "normal";
    icon = "system-log-out";
    appName = "Power";
    summary = "Logging out...";
    timeout = 2000;
  };

  notifyReboot = config.notifications.send {
    urgency = "normal";
    icon = "system-reboot";
    appName = "Power";
    summary = "Rebooting system...";
    timeout = 2000;
  };

  notifyShutdown = config.notifications.send {
    urgency = "normal";
    icon = "system-shutdown";
    appName = "Power";
    summary = "Shutting down system...";
    timeout = 2000;
  };

  notifyStatus = config.notifications.send {
    urgency = "low";
    icon = "computer";
    appName = "Power Status";
    summary = "System Status";
    body = "Uptime: \$uptime_info\\nLoad: \$load_avg\\nHypridle: \$hypridle_status\\n\$battery_status";
    hints = {
      "string:x-dunst-stack-tag" = "powerStatus";
    };
  };

in {
  power = pkgs.writeShellScriptBin "power-control" ''
    #!/usr/bin/env bash

    # Power management control script for Hyprland with hypridle integration

    case "$1" in
      suspend)
        # Use systemctl to trigger proper suspend with hypridle handling
        ${notifySuspend}
        ${pkgs.systemd}/bin/systemctl suspend
        ;;

      hibernate)
        # Use systemctl to trigger proper hibernate with hypridle handling
        ${notifyHibernate}
        ${pkgs.systemd}/bin/systemctl hibernate
        ;;

      logout)
        # Confirm logout
        if [ "$2" = "--confirm" ] || ${pkgs.coreutils}/bin/echo -e "y\nn" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Logout? (y/N)" | ${pkgs.gnugrep}/bin/grep -q "^[Yy]"; then
          ${notifyLogout}
          ${pkgs.coreutils}/bin/sleep 1
          ${pkgs.hyprland}/bin/hyprctl dispatch exit
        fi
        ;;

      reboot)
        # Confirm reboot
        if [ "$2" = "--confirm" ] || ${pkgs.coreutils}/bin/echo -e "y\nn" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Reboot? (y/N)" | ${pkgs.gnugrep}/bin/grep -q "^[Yy]"; then
          ${notifyReboot}
          ${pkgs.coreutils}/bin/sleep 1
          ${pkgs.systemd}/bin/systemctl reboot
        fi
        ;;

      shutdown)
        # Confirm shutdown
        if [ "$2" = "--confirm" ] || ${pkgs.coreutils}/bin/echo -e "y\nn" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Shutdown? (y/N)" | ${pkgs.gnugrep}/bin/grep -q "^[Yy]"; then
          ${notifyShutdown}
          ${pkgs.coreutils}/bin/sleep 1
          ${pkgs.systemd}/bin/systemctl poweroff
        fi
        ;;

      lock)
        # Manually trigger lock (hypridle handles automatic locking)
        ${pkgs.systemd}/bin/loginctl lock-session
        ;;

      menu)
        # Show power menu using walker
        choice=$(${pkgs.coreutils}/bin/echo -e "🔒 Lock\n💤 Suspend\n🛌 Hibernate\n🚪 Logout\n🔄 Reboot\n⏻ Shutdown" | ${pkgs.walker}/bin/walker --dmenu --placeholder "Power Options")

        case "$choice" in
          "🔒 Lock")
            power-control lock
            ;;
          "💤 Suspend")
            power-control suspend
            ;;
          "🛌 Hibernate")
            power-control hibernate
            ;;
          "🚪 Logout")
            power-control logout --confirm
            ;;
          "🔄 Reboot")
            power-control reboot --confirm
            ;;
          "⏻ Shutdown")
            power-control shutdown --confirm
            ;;
        esac
        ;;

      status)
        # Show power status notification
        battery_status=""
        if ${pkgs.which}/bin/which ${pkgs.upower}/bin/upower >/dev/null 2>&1; then
          battery_info=$(${pkgs.upower}/bin/upower -i $(${pkgs.upower}/bin/upower -e | ${pkgs.gnugrep}/bin/grep 'BAT') 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E "state|percentage" | ${pkgs.gnused}/bin/sed 's/.*: *//' | ${pkgs.coreutils}/bin/tr '\n' ' ')
          if [ -n "$battery_info" ]; then
            battery_status="Battery: $battery_info"
          fi
        fi

        uptime_info=$(${pkgs.procps}/bin/uptime -p)
        load_avg=$(${pkgs.procps}/bin/uptime | ${pkgs.gawk}/bin/awk -F'load average:' '{print $2}' | ${pkgs.gnused}/bin/sed 's/^ *//')

        # Check if hypridle is running
        hypridle_status="❌ Not running"
        if ${pkgs.procps}/bin/pgrep -x "hypridle" > /dev/null; then
          hypridle_status="✅ Running"
        fi

        ${notifyStatus}
        ;;

      *)
        ${pkgs.coreutils}/bin/echo "Usage: power-control {suspend|hibernate|logout|reboot|shutdown|lock|menu|status}"
        ${pkgs.coreutils}/bin/echo "  suspend    - Suspend the system (hypridle handles locking)"
        ${pkgs.coreutils}/bin/echo "  hibernate  - Hibernate the system (hypridle handles locking)"
        ${pkgs.coreutils}/bin/echo "  logout     - Logout from Hyprland (with confirmation)"
        ${pkgs.coreutils}/bin/echo "  reboot     - Reboot the system (with confirmation)"
        ${pkgs.coreutils}/bin/echo "  shutdown   - Shutdown the system (with confirmation)"
        ${pkgs.coreutils}/bin/echo "  lock       - Lock the screen manually"
        ${pkgs.coreutils}/bin/echo "  menu       - Show power options menu"
        ${pkgs.coreutils}/bin/echo "  status     - Show power status including hypridle"
        exit 1
        ;;
    esac
  '';
}

