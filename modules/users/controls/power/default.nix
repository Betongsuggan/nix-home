{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.controls.power;

  # Build dmenu commands with specific prompts
  dmenuLogout = config.launcher.dmenu { prompt = "Logout? (y/N)"; };
  dmenuReboot = config.launcher.dmenu { prompt = "Reboot? (y/N)"; };
  dmenuShutdown = config.launcher.dmenu { prompt = "Shutdown? (y/N)"; };
  dmenuPowerMenu = config.launcher.dmenu { prompt = "Power Options"; };

  # Build notification commands using the notifications module
  notifySuspend = optionalString cfg.notifications (config.notifications.send {
    urgency = "normal";
    icon = "system-suspend";
    appName = "Power";
    summary = "Suspending system...";
    timeout = 2000;
  });

  notifyHibernate = optionalString cfg.notifications (config.notifications.send {
    urgency = "normal";
    icon = "system-hibernate";
    appName = "Power";
    summary = "Hibernating system...";
    timeout = 2000;
  });

  notifyLogout = optionalString cfg.notifications (config.notifications.send {
    urgency = "normal";
    icon = "system-log-out";
    appName = "Power";
    summary = "Logging out...";
    timeout = 2000;
  });

  notifyReboot = optionalString cfg.notifications (config.notifications.send {
    urgency = "normal";
    icon = "system-reboot";
    appName = "Power";
    summary = "Rebooting system...";
    timeout = 2000;
  });

  notifyShutdown = optionalString cfg.notifications (config.notifications.send {
    urgency = "normal";
    icon = "system-shutdown";
    appName = "Power";
    summary = "Shutting down system...";
    timeout = 2000;
  });

  notifyStatus = optionalString cfg.notifications (config.notifications.send {
    urgency = "low";
    icon = "computer";
    appName = "Power Status";
    summary = "System Status";
    body = "Uptime: \$uptime_info\\nLoad: \$load_avg\\nHypridle: \$hypridle_status\\n\$battery_status";
    hints = {
      "string:x-dunst-stack-tag" = "powerStatus";
    };
  });

  # Window manager specific commands
  wmCommands = {
    hyprland = {
      logout = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
    };
    i3 = {
      logout = "${pkgs.i3}/bin/i3-msg exit";
    };
    niri = {
      logout = "niri msg action quit --skip-confirmation";
    };
    sway = {
      logout = "${pkgs.sway}/bin/swaymsg exit";
    };
    generic = {
      logout = "${pkgs.systemd}/bin/loginctl terminate-session";
    };
  };

  wm = wmCommands.${config.controls.windowManager};

  powerControl = pkgs.writeShellScriptBin "power-control" ''
    #!/usr/bin/env bash

    # Power management control script with window manager integration

    case "$1" in
      suspend)
        # Use systemctl to trigger proper suspend
        ${notifySuspend}
        ${pkgs.systemd}/bin/systemctl suspend
        ;;

      hibernate)
        # Use systemctl to trigger proper hibernate
        ${notifyHibernate}
        ${pkgs.systemd}/bin/systemctl hibernate
        ;;

      logout)
        # Confirm logout
        ${optionalString cfg.confirmActions ''
        if [ "$2" != "--confirm" ] && ! ${pkgs.coreutils}/bin/echo -e "y\nn" | ${dmenuLogout} | ${pkgs.gnugrep}/bin/grep -q "^[Yy]"; then
          exit 0
        fi
        ''}
        ${notifyLogout}
        ${pkgs.coreutils}/bin/sleep 1
        ${wm.logout}
        ;;

      reboot)
        # Confirm reboot
        ${optionalString cfg.confirmActions ''
        if [ "$2" != "--confirm" ] && ! ${pkgs.coreutils}/bin/echo -e "y\nn" | ${dmenuReboot} | ${pkgs.gnugrep}/bin/grep -q "^[Yy]"; then
          exit 0
        fi
        ''}
        ${notifyReboot}
        ${pkgs.coreutils}/bin/sleep 1
        ${pkgs.systemd}/bin/systemctl reboot
        ;;

      shutdown)
        # Confirm shutdown
        ${optionalString cfg.confirmActions ''
        if [ "$2" != "--confirm" ] && ! ${pkgs.coreutils}/bin/echo -e "y\nn" | ${dmenuShutdown} | ${pkgs.gnugrep}/bin/grep -q "^[Yy]"; then
          exit 0
        fi
        ''}
        ${notifyShutdown}
        ${pkgs.coreutils}/bin/sleep 1
        ${pkgs.systemd}/bin/systemctl poweroff
        ;;

      lock)
        # Manually trigger lock
        ${pkgs.systemd}/bin/loginctl lock-session
        ;;

      menu)
        # Show power menu using configured launcher
        choice=$(${pkgs.coreutils}/bin/echo -e "🔒 Lock\n💤 Suspend\n🛌 Hibernate\n🚪 Logout\n🔄 Reboot\n⏻ Shutdown" | ${dmenuPowerMenu})

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

        # Check if hypridle is running (window manager specific)
        hypridle_status="❌ Not running"
        if ${pkgs.procps}/bin/pgrep -x "hypridle" > /dev/null; then
          hypridle_status="✅ Running"
        fi

        ${notifyStatus}
        ;;

      *)
        ${pkgs.coreutils}/bin/echo "Usage: power-control {suspend|hibernate|logout|reboot|shutdown|lock|menu|status}"
        ${pkgs.coreutils}/bin/echo "  suspend    - Suspend the system"
        ${pkgs.coreutils}/bin/echo "  hibernate  - Hibernate the system"
        ${pkgs.coreutils}/bin/echo "  logout     - Logout from window manager${optionalString cfg.confirmActions " (with confirmation)"}"
        ${pkgs.coreutils}/bin/echo "  reboot     - Reboot the system${optionalString cfg.confirmActions " (with confirmation)"}"
        ${pkgs.coreutils}/bin/echo "  shutdown   - Shutdown the system${optionalString cfg.confirmActions " (with confirmation)"}"
        ${pkgs.coreutils}/bin/echo "  lock       - Lock the screen"
        ${pkgs.coreutils}/bin/echo "  menu       - Show power options menu"
        ${pkgs.coreutils}/bin/echo "  status     - Show power status"
        exit 1
        ;;
    esac
  '';
in
{
  config = mkIf (config.controls.enable && cfg.enable) {
    home.packages = [
      powerControl
      pkgs.systemd
      pkgs.upower
    ] ++ optionals (config.controls.windowManager == "hyprland") [
      pkgs.hyprland
    ] ++ optionals (config.controls.windowManager == "i3") [
      pkgs.i3
    ] ++ optionals (config.controls.windowManager == "sway") [
      pkgs.sway
    ];
  };
}