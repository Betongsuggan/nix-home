{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.my.fleet-status;
  port = inputs.self.lib.tailnet.statusPort;

  # The host's restic jobs (modules/restic-backup)
  backupUnits = map (n: "restic-backups-${n}") (attrNames config.services.restic.backups);

  # One status document per connection, as a bare HTTP/1.0 response
  status = pkgs.writeShellApplication {
    name = "fleet-status";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      systemd
    ];
    text = ''
      # The request line; nothing in it matters
      read -r -t 2 _ || true

      battery=null
      for b in /sys/class/power_supply/BAT*; do
        [ -r "$b/capacity" ] || continue
        battery=$(jq -n --argjson capacity "$(cat "$b/capacity")" --arg state "$(cat "$b/status")" \
          '{ $capacity, $state }')
        break
      done

      read -r used avail < <(df --output=pcent,avail -B1 / | tail -n 1 | tr -d '%')

      backups='[]'
      for unit in ${escapeShellArgs backupUnits}; do
        at=$(systemctl show "$unit.service" --timestamp=unix -P ExecMainExitTimestamp)
        result=$(systemctl show "$unit.service" -P Result)
        backups=$(jq -c --arg unit "$unit" --arg at "''${at#@}" --arg result "$result" \
          '. + [{ $unit, at: ($at | tonumber? // null), $result }]' <<<"$backups")
      done

      printf 'HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n'
      jq -cn \
        --arg host ${escapeShellArg config.my.common.host} \
        --argjson uptime "$(cut -d' ' -f1 /proc/uptime)" \
        --argjson battery "$battery" \
        --argjson diskUsed "$used" \
        --argjson diskFree "$avail" \
        --argjson backups "$backups" \
        --arg system "$(readlink /run/current-system)" \
        --arg booted "$(readlink /run/booted-system)" \
        --argjson rebuilt "$(stat -c %Y /nix/var/nix/profiles/system)" \
        '{ $host, $uptime, $battery, disk: { usedPercent: $diskUsed, free: $diskFree },
           $backups, $system, rebootPending: ($system != $booted), $rebuilt }'
    '';
  };
in
{
  options.my.fleet-status.enable = mkOption {
    type = types.bool;
    default = config.services.tailscale.enable;
    defaultText = literalExpression "config.services.tailscale.enable";
    description = ''
      Serve this host's status (battery, disk, uptime, backups, running
      system) as JSON on the tailnet, for the fleet dashboard. Socket
      activated: nothing runs between requests.
    '';
  };

  config = mkIf cfg.enable {
    systemd.sockets.fleet-status = {
      description = "Fleet status (tailnet)";
      wantedBy = [ "sockets.target" ];
      listenStreams = [ (toString port) ];
      socketConfig.Accept = true;
    };

    systemd.services."fleet-status@" = {
      description = "Fleet status response";
      serviceConfig = {
        ExecStart = getExe status;
        StandardInput = "socket";
        StandardOutput = "socket";
        StandardError = "journal";
        DynamicUser = true;
        RuntimeMaxSec = 10;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # Reachable over the tailnet only
    networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
      port
    ];
  };
}
