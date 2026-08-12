{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.network-monitor;

  nmcli = "${pkgs.networkmanager}/bin/nmcli";

  # Notification commands using the notifications module
  notifyWifiConnected = config.notifications.send {
    category = "network";
    summary = "Connected to \$ssid";
  };

  # State-specific *-disconnected/-offline icons only exist in Papirus'
  # panel/ context, which dunst's icon path doesn't cover — stick to
  # resolvable icons and let the headline convey the state.
  notifyWifiDisconnected = config.notifications.send {
    category = "network";
    summary = "Wi-Fi disconnected";
  };

  notifyEthernetConnected = config.notifications.send {
    category = "network";
    icon = "network-wired";
    summary = "Ethernet connected";
  };

  notifyEthernetDisconnected = config.notifications.send {
    category = "network";
    icon = "network-wired";
    summary = "Ethernet disconnected";
  };

  notifyConnectivityLost = config.notifications.send {
    category = "network";
    icon = "network-disconnect";
    urgency = "normal";
    summary = "No internet connection";
  };

  notifyConnectivityRestored = config.notifications.send {
    category = "network";
    icon = "network-connect";
    summary = "Internet connection restored";
  };

  notifyTailscaleUp = config.notifications.send {
    category = "network";
    icon = "network-vpn";
    summary = "Tailscale connected";
  };

  notifyTailscaleDown = config.notifications.send {
    category = "network";
    icon = "network-vpn";
    urgency = "normal";
    summary = "Tailscale disconnected";
  };

  networkMonitorScript = pkgs.writeShellScriptBin "network-monitor" ''
    #!/usr/bin/env bash

    handle_device() {
      local dev="$1" event="$2" type ssid
      type=$(${nmcli} -g GENERAL.TYPE device show "$dev" 2>/dev/null)
      case "$type" in
        wifi)
          if [ "$event" = up ]; then
            ssid=$(${nmcli} -g GENERAL.CONNECTION device show "$dev" 2>/dev/null)
            ${notifyWifiConnected}
          else
            ${notifyWifiDisconnected}
          fi
          ;;
        ethernet)
          if [ "$event" = up ]; then
            ${notifyEthernetConnected}
          else
            ${notifyEthernetDisconnected}
          fi
          ;;
      esac
    }

    monitor_networkmanager() {
      # Seed connectivity so a restart doesn't re-announce the current state
      local connectivity dev
      connectivity=$(${nmcli} -g CONNECTIVITY general)

      ${nmcli} monitor | while read -r line; do
        case "$line" in
          "Connectivity is now 'none'"* | "Connectivity is now 'limited'"*)
            if [ "$connectivity" = full ]; then
              ${notifyConnectivityLost}
            fi
            connectivity=none
            ;;
          "Connectivity is now 'full'"*)
            if [ "$connectivity" = none ]; then
              ${notifyConnectivityRestored}
            fi
            connectivity=full
            ;;
          # "disconnected" must match before "connected" (substring collision)
          *": disconnected")
            dev="''${line%%:*}"
            handle_device "$dev" down
            ;;
          *": connected")
            dev="''${line%%:*}"
            handle_device "$dev" up
            ;;
        esac
      done
    }

    monitor_tailscale() {
      # tailscale0 is a TUN device whose operstate stays "unknown", so link
      # state is unreliable; the tailnet address being added/removed is the
      # robust up/down signal.
      ${pkgs.iproute2}/bin/ip -o monitor address | while read -r line; do
        case "$line" in
          *" tailscale0 "*inet6*) ;;
          Deleted*" tailscale0 "*inet*)
            ${notifyTailscaleDown}
            ;;
          *" tailscale0 "*inet*)
            ${notifyTailscaleUp}
            ;;
        esac
      done
    }

    monitor_networkmanager &
    monitor_tailscale &
    wait
  '';

in
{
  options.network-monitor = {
    enable = mkEnableOption "desktop notifications for network events";
  };

  config = mkIf cfg.enable {
    # Auto-enable notifications when network-monitor is enabled
    notifications.enable = mkDefault true;

    home.packages = [ networkMonitorScript ];

    systemd.user.services.network-monitor = {
      Unit = {
        Description = "Network event notifications";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${networkMonitorScript}/bin/network-monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
