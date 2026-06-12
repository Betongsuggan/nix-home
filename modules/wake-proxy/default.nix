{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wake-proxy;

  wakeAndProxy = port: pkgs.writeShellScript "wake-and-proxy-${toString port}" ''
    set -u
    HOST='${cfg.targetHost}'
    PORT='${toString port}'
    MAC='${cfg.targetMac}'
    TIMEOUT=${toString cfg.wakeTimeoutSec}

    probe() {
      ${pkgs.netcat-openbsd}/bin/nc -z -w1 "$HOST" "$PORT"
    }

    if ! probe; then
      ${pkgs.wakeonlan}/bin/wakeonlan ${optionalString (cfg.broadcastAddress != null) "-i ${cfg.broadcastAddress}"} "$MAC" >&2 || true
      end=$(( $(date +%s) + TIMEOUT ))
      until probe; do
        if [ "$(date +%s)" -ge "$end" ]; then
          echo "wake-proxy: $HOST:$PORT did not come up within ''${TIMEOUT}s" >&2
          exit 1
        fi
        sleep 1
      done
    fi

    exec ${pkgs.socat}/bin/socat - "TCP:$HOST:$PORT"
  '';

  mkSocket = port: nameValuePair "wake-proxy-${toString port}" {
    description = "Wake-proxy listener on TCP ${toString port}";
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "0.0.0.0:${toString port}";
      Accept = true;
    };
  };

  mkService = port: nameValuePair "wake-proxy-${toString port}@" {
    description = "Wake-proxy handler for TCP ${toString port}";
    serviceConfig = {
      ExecStart = "${wakeAndProxy port}";
      StandardInput = "socket";
      StandardOutput = "socket";
      StandardError = "journal";
    };
  };
in
{
  options.wake-proxy = {
    enable = mkEnableOption "Wake-on-LAN reverse proxy (sends a magic packet on demand)";

    targetMac = mkOption {
      type = types.str;
      example = "aa:bb:cc:dd:ee:ff";
      description = "MAC address to wake when the upstream is unreachable.";
    };

    targetHost = mkOption {
      type = types.str;
      example = "100.64.0.5";
      description = ''
        Hostname or IP of the upstream. A tailnet IP is recommended — once the
        target is woken, the tailscale daemon will come back up and the same
        address will start responding.
      '';
    };

    ports = mkOption {
      type = types.listOf types.port;
      default = [ 11434 ];
      description = ''
        TCP ports to proxy. Each port listens on the proxy host and is forwarded
        to the same port on the upstream. WoL fires on the first connection
        when the upstream is unreachable.
      '';
    };

    wakeTimeoutSec = mkOption {
      type = types.int;
      default = 60;
      description = "Seconds to wait for the upstream port to open after WoL.";
    };

    broadcastAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.168.50.255";
      description = ''
        Broadcast address for the magic packet. Leave null to use wakeonlan's
        default (255.255.255.255), which works when the proxy host and the
        target share an L2 segment.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.sockets = listToAttrs (map mkSocket cfg.ports);
    systemd.services = listToAttrs (map mkService cfg.ports);
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = cfg.ports;
  };
}
