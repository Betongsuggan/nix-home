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
  selfLib = inputs.self.lib;
  self = config.my.common.host;
  port = selfLib.tailnet.statusPort;

  # The host's restic jobs (modules/restic-backup)
  backupUnits = map (n: "restic-backups-${n}") (attrNames config.services.restic.backups);

  # Registry tailnet IP → host name, for identifying who announces a state
  peersByIp = filterAttrs (ip: _: ip != "") (
    listToAttrs (mapAttrsToList (name: h: nameValuePair (h.tailnetIp or "") name) selfLib.hosts)
  );

  # One status document per connection, as a bare HTTP/1.0 response; or a
  # peer's announced power state, stored for the next status document.
  status = pkgs.writeShellApplication {
    name = "fleet-status";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      systemd
    ];
    text = ''
      reply() { printf 'HTTP/1.0 %s\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n' "$1"; }

      # Request line, then headers (only Content-Length matters). Reading the
      # whole request matters: closing the socket with unread input makes the
      # kernel send a reset, which discards the response before the client
      # has read it
      IFS=' ' read -r -t 2 method path _ || exit 0
      length=0
      while IFS= read -r -t 2 line && [ -n "''${line%$'\r'}" ]; do
        case "''${line,,}" in
          content-length:*) length=''${line#*: }; length=''${length%$'\r'} ;;
        esac
      done

      peers=$STATE_DIRECTORY/peers

      if [ "$method" = POST ] && [ "$path" = /state ]; then
        # A peer's last word before it suspends or shuts down. The sender is
        # whoever systemd says connected (REMOTE_ADDR), matched against the
        # registry: tailnet IPs only, no self-declared names
        case "''${REMOTE_ADDR:-}" in
      ${concatStringsSep "\n" (
        mapAttrsToList (ip: name: "    ${ip}) peer=${escapeShellArg name} ;;") peersByIp
      )}
          *) reply '403 Forbidden'; exit 0 ;;
        esac
        body=""
        [ "$length" -gt 0 ] && [ "$length" -le 1024 ] && IFS= read -r -N "$length" body
        state=$(jq -r '.state | select(. == "suspend" or . == "shutdown" or . == "resume")' <<<"$body" 2>/dev/null) || state=""
        if [ -z "$state" ]; then reply '400 Bad Request'; exit 0; fi
        mkdir -p "$peers"
        jq -cn --arg state "$state" --argjson at "$(date +%s)" '{ $state, $at }' > "$peers/$peer.json.tmp"
        mv "$peers/$peer.json.tmp" "$peers/$peer.json"
        reply '204 No Content'
        exit 0
      fi

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

      # What peers last announced (modules/fleet-status announceTo), by host
      peersJson='{}'
      for f in "$peers"/*.json; do
        [ -s "$f" ] || continue
        peersJson=$(jq -c --arg host "$(basename "$f" .json)" --slurpfile s "$f" '. + { ($host): $s[0] }' <<<"$peersJson")
      done

      reply '200 OK'
      jq -cn \
        --arg host ${escapeShellArg self} \
        --argjson uptime "$(cut -d' ' -f1 /proc/uptime)" \
        --argjson battery "$battery" \
        --argjson diskUsed "$used" \
        --argjson diskFree "$avail" \
        --argjson backups "$backups" \
        --arg system "$(readlink /run/current-system)" \
        --arg booted "$(readlink /run/booted-system)" \
        --argjson rebuilt "$(stat -c %Y /nix/var/nix/profiles/system)" \
        --argjson peers "$peersJson" \
        '{ $host, $uptime, $battery, disk: { usedPercent: $diskUsed, free: $diskFree },
           $backups, $system, rebootPending: ($system != $booted), $rebuilt, $peers }'
    '';
  };

  # `fleet-announce suspend|shutdown|resume`: tell the relay before going.
  # By tailnet IP where the registry has one (no DNS on the way down).
  relay = cfg.announceTo;
  relayAddress =
    if relay == null then null else selfLib.hosts.${relay}.tailnetIp or (selfLib.tailnet.fqdn relay);
  announce = pkgs.writeShellApplication {
    name = "fleet-announce";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      case "''${1:-}" in
        suspend | shutdown | resume) ;;
        *) echo "usage: fleet-announce suspend|shutdown|resume" >&2; exit 64 ;;
      esac
      curl -sS -m 3 -o /dev/null -X POST --data "{\"state\":\"$1\"}" \
        "http://${relayAddress}:${toString port}/state" \
        || echo "fleet-announce: ${relay} didn't take '$1'" >&2
    '';
  };
in
{
  options.my.fleet-status = {
    enable = mkOption {
      type = types.bool;
      default = config.services.tailscale.enable;
      defaultText = literalExpression "config.services.tailscale.enable";
      description = ''
        Serve this host's status (battery, disk, uptime, backups, running
        system, what peers last announced) as JSON on the tailnet, for the
        fleet dashboard, and accept peers' suspend/shutdown announcements.
        Socket activated: nothing runs between requests.
      '';
    };

    announceTo = mkOption {
      type = types.nullOr types.str;
      default = selfLib.hosts.${self}.wol.relay or null;
      defaultText = literalMD "this host's WoL relay from the registry (`hosts.<host>.wol.relay`), if any";
      description = ''
        A host to tell before suspending or shutting down (and after
        resuming), so the dashboard can show "asleep" or "shut down" instead
        of tailscale's "offline". The natural choice is the host that wakes
        this one, which is always on while this one is not.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
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
          # Peers' announcements, one file per host
          StateDirectory = "fleet-status";
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
    })

    (mkIf (cfg.announceTo != null) {
      environment.systemPackages = [ announce ];

      # Before any sleep; sleep.target is not part of a shutdown, so a
      # suspend never masquerades as one
      systemd.services.fleet-announce-sleep = {
        description = "Tell ${relay} this host is suspending";
        wantedBy = [ "sleep.target" ];
        before = [ "sleep.target" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${getExe announce} suspend";
        };
      };

      # Clears the "asleep" the moment the host is back, before tailscale
      # has reconnected
      powerManagement.resumeCommands = "${getExe announce} resume || true";

      # Stops (so announces) on the way down, while tailscaled is still up:
      # units stop in reverse start order, and this one starts after it
      systemd.services.fleet-announce-shutdown = {
        description = "Tell ${relay} this host is shutting down";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
          ExecStop = "${getExe announce} shutdown";
          TimeoutStopSec = 5;
        };
      };
    })
  ];
}
