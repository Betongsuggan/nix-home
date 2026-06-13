{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wake-proxy;

  wake-proxy-pkg = pkgs.buildGoModule {
    pname = "wake-proxy";
    version = "0.1.0";
    src = ./src;
    vendorHash = null;
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
        to the same port on the upstream. WoL fires when the cached "upstream
        alive" flag is false and a fresh probe confirms it.
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
    systemd.services.wake-proxy = {
      description = "Wake-on-LAN reverse proxy (long-running TCP forwarder)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.wakeonlan ];

      environment = {
        WAKE_PROXY_MAC = cfg.targetMac;
        WAKE_PROXY_HOST = cfg.targetHost;
        WAKE_PROXY_PORTS = concatStringsSep "," (map toString cfg.ports);
        WAKE_PROXY_TIMEOUT_SEC = toString cfg.wakeTimeoutSec;
      } // optionalAttrs (cfg.broadcastAddress != null) {
        WAKE_PROXY_BROADCAST = cfg.broadcastAddress;
      };

      serviceConfig = {
        Type = "exec";
        ExecStart = "${wake-proxy-pkg}/bin/wake-proxy";
        Restart = "on-failure";
        RestartSec = "5s";
        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = cfg.ports;
  };
}
