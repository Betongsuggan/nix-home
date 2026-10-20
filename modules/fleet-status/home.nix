{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:
with lib;

let
  cfg = config.my.fleet-status.dashboard;
  selfLib = inputs.self.lib;
  self = osConfig.my.common.host;
  targets = selfLib.sshTargetsOf self config.home.username;
  canSsh = host: any (t: t.host == host) targets;
  # The plug-<name> commands (modules/shelly-plug), when this host has them
  plugsEnabled = osConfig.my.shelly-plug.enable;

  # Every registry host with what this user can do there, from the registry:
  # SSH where sshFrom allows it, wake where its relay is reachable by SSH
  hosts = mapAttrsToList (
    name: h:
    let
      relay = h.wol.relay or null;
    in
    {
      inherit name;
      fqdn = selfLib.tailnet.fqdn name;
      tailnetName = h.hostName;
      isSelf = name == self;
      ssh = canSsh name;
      wake =
        if relay != null && (relay == self || canSsh relay) && h.wol.mac != "00:00:00:00:00:00" then
          (if relay == self then "wake-${name}" else "ssh ${relay} wake-${name}")
        else
          null;
      # The smart plug the host is powered through (registry hosts.<h>.plug)
      plug = if plugsEnabled then h.plug or null else null;
    }
  ) selfLib.hosts;

  hostsJson = pkgs.writeText "fleet-hosts.json" (builtins.toJSON hosts);
  dmenu = prompt: config.my.launcher.dmenu { inherit prompt; };
  notify =
    summary: body:
    config.my.notifications.send {
      appName = "Fleet";
      icon = "network-server";
      inherit summary body;
    };

  dashboard = pkgs.writeShellApplication {
    name = "fleet-dashboard";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        curl
        jq
        tailscale
        wl-clipboard
        openssh
        git
      ]
      ++ optional plugsEnabled osConfig.my.shelly-plug.package;
    # nix itself comes from the system (the one the flake is built with)
    text = ''
      hosts=${hostsJson}
      dir=$(mktemp -d)
      trap 'rm -rf "$dir"' EXIT

      # The status of every host tailscale sees online, in parallel. Asleep or
      # absent ones would only hit the timeout, so they aren't asked (all are
      # when tailscale itself can't answer).
      tailscale status --json > "$dir/tailscale.json" 2>/dev/null || echo '{}' > "$dir/tailscale.json"
      for fqdn in $(jq -r --slurpfile ts "$dir/tailscale.json" '
        ($ts[0] | [(.Self // empty), ((.Peer // {}) | .[])] | map(select(.Online) | .HostName)) as $online
        | .[] | select(($online | length) == 0 or (.tailnetName | IN($online[]))) | .fqdn
      ' "$hosts"); do
        curl -sf -m 2 "http://$fqdn:${toString selfLib.tailnet.statusPort}/" > "$dir/$fqdn.json" &
      done
      # And the plugs of hosts that have one: a powered-off host still shows
      # its plug, which is the moment that matters
      for plug in $(jq -r '.[] | .plug // empty' "$hosts"); do
        "plug-$plug" status > "$dir/plug-$plug.json" 2>/dev/null &
      done
      wait

      # One line per host: its status, or tailscale's view when it can't answer
      line() {
        local name=$1 fqdn=$2 tsname=$3 self=$4 plug=$5 file="$dir/$2.json"
        local power=""
        if [ -n "$plug" ] && [ -s "$dir/plug-$plug.json" ]; then
          power=$(jq -r 'if .output then "power on \(.apower | round) W" else "power off" end' "$dir/plug-$plug.json")
        fi
        if [ -s "$file" ]; then
          jq -r --arg name "$name" --arg self "$self" --arg power "$power" '
            def ago: (now - .) as $s
              | if $s < 3600 then "\($s / 60 | floor)m"
                elif $s < 86400 then "\($s / 3600 | floor)h" else "\($s / 86400 | floor)d" end;
            def dur: if . < 3600 then "\(. / 60 | floor)m"
                     elif . < 86400 then "\(. / 3600 | floor)h" else "\(. / 86400 | floor)d" end;
            [ "● \($name)" + (if $self == "true" then " (this)" else "" end),
              (.battery | select(. != null) | "battery \(.capacity)%" + (if .state == "Charging" then "+" else "" end)),
              "disk \(.disk.usedPercent)%",
              "up \(.uptime | dur)",
              "rebuilt \(.rebuilt | ago) ago",
              (.backups | map(select(.at != null)) | max_by(.at) | select(. != null)
                | "backup \(.at | ago) ago" + (if .result != "success" then " (FAILED)" else "" end)),
              (select(.rebootPending) | "reboot pending"),
              ($power | select(. != ""))
            ] | join(" · ")' "$file"
        else
          local state seen
          read -r state seen < <(jq -r --arg ts "$tsname" '
            ([(.Self // empty), ((.Peer // {}) | .[])] | map(select(.HostName == $ts)) | first)
            | if . == null then "absent -" elif .Online then "online -" else "asleep \(.LastSeen)" end
          ' "$dir/tailscale.json")
          case "$state" in
            absent) echo "✗ $name · not on the tailnet''${power:+ · $power}" ;;
            online) echo "◐ $name · online, no status''${power:+ · $power}" ;;
            *)
              local s
              s=$(( $(date +%s) - $(date -d "$seen" +%s 2>/dev/null || date +%s) ))
              if [ "$s" -lt 3600 ]; then s="$((s / 60))m"
              elif [ "$s" -lt 86400 ]; then s="$((s / 3600))h"
              else s="$((s / 86400))d"; fi
              echo "○ $name · asleep · seen $s ago''${power:+ · $power}"
              ;;
          esac
        fi
      }

      names=() ; labels=()
      while IFS=$'\t' read -r name fqdn tsname self plug; do
        names+=("$name")
        labels+=("$(line "$name" "$fqdn" "$tsname" "$self" "$plug")")
      done < <(jq -r '.[] | [.name, .fqdn, .tailnetName, (.isSelf | tostring), (.plug // "")] | @tsv' "$hosts")

      choice=$(printf '%s\n' "''${labels[@]}" | ${dmenu "Fleet"}) || exit 0
      host=""
      for i in "''${!labels[@]}"; do
        if [ "''${labels[$i]}" = "$choice" ]; then host=''${names[$i]}; fi
      done
      [ -n "$host" ] || exit 0

      entry=$(jq -c --arg h "$host" '.[] | select(.name == $h)' "$hosts")
      fqdn=$(jq -r .fqdn <<<"$entry")

      actions=()
      if [ "$(jq -r .ssh <<<"$entry")" = true ]; then actions+=("SSH"); fi
      if [ "$(jq -r '.wake != null' <<<"$entry")" = true ]; then actions+=("Wake"); fi
      plug=$(jq -r '.plug // empty' <<<"$entry")
      if [ -n "$plug" ]; then actions+=("Power on" "Power off"); fi
      if [ -d ${escapeShellArg cfg.flake} ]; then actions+=("Check if a rebuild is needed"); fi
      if [ -s "$dir/$fqdn.json" ]; then actions+=("Details"); fi
      actions+=("Copy address")

      action=$(printf '%s\n' "''${actions[@]}" | ${dmenu "Action"}) || exit 0
      case "$action" in
        SSH)
          exec ${config.my.terminal.command} -e ssh "$host"
          ;;
        Wake)
          if eval "$(jq -r .wake <<<"$entry")"; then
            ${notify "Waking $host" "Magic packet sent"}
          else
            ${notify "Could not wake $host" "The relay didn't answer"}
          fi
          ;;
        "Power on")
          if "plug-$plug" on > /dev/null; then
            ${notify "Powering on $host" "Plug $plug is on; Wake it if the BIOS doesn't start it"}
          else
            ${notify "Could not reach plug $plug" "No answer from the plug"}
          fi
          ;;
        "Power off")
          if [ "$(jq -r .isSelf <<<"$entry")" = true ]; then
            ${notify "Refused" "Plug $plug powers this host"}
            exit 0
          fi
          [ "$(printf 'No\nYes\n' | ${dmenu "Cut the power?"})" = Yes ] || exit 0
          if "plug-$plug" off > /dev/null; then
            ${notify "Powered off $host" "Plug $plug is off"}
          else
            ${notify "Could not reach plug $plug" "No answer from the plug"}
          fi
          ;;
        "Check if a rebuild is needed")
          if [ ! -s "$dir/$fqdn.json" ]; then
            ${notify "$host" "It isn't answering, so its running system is unknown"}
            exit 0
          fi
          running=$(jq -r .system "$dir/$fqdn.json")
          ${notify "Checking $host" "Evaluating ~/nix-home ($(git -C ${escapeShellArg cfg.flake} rev-parse --short HEAD))..."}
          wanted=$(nix eval --raw ${escapeShellArg cfg.flake}"#nixosConfigurations.$host.config.system.build.toplevel.outPath" 2>/dev/null) || {
            ${notify "$host" "Evaluating nix-home failed"}
            exit 0
          }
          if [ "$running" = "$wanted" ]; then
            ${notify "$host is up to date" "It runs what ~/nix-home builds"}
          else
            ${notify "$host needs a rebuild" "It runs a different system than ~/nix-home builds"}
          fi
          ;;
        Details)
          jq -r '
            [ "host: \(.host)", "system: \(.system)", "rebuilt: \(.rebuilt | todate)",
              "disk: \(.disk.usedPercent)% used, \(.disk.free / 1e9 | floor) GB free",
              (.battery | select(. != null) | "battery: \(.capacity)% \(.state)"),
              (.backups[] | "\(.unit): \(if .at then (.at | todate) else "never" end) \(.result)") ]
            | .[]' "$dir/$fqdn.json" | ${dmenu "Details"} > /dev/null || true
          ;;
        "Copy address")
          printf '%s' "$fqdn" | wl-copy
          ${notify "Copied" "$fqdn"}
          ;;
      esac
    '';
  };
in
{
  options.my.fleet-status.dashboard = {
    enable = mkOption {
      type = types.bool;
      default = config.my.profiles.desktop.enable && elem config.home.username osConfig.my.common.admins;
      defaultText = literalMD "an admin (`my.common.admins`) with the desktop profile";
      description = "The fleet dashboard: every host's status, and SSH, wake and rebuild checks, in the launcher.";
    };
    flake = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/nix-home";
      description = "The nix-home checkout that \"Check if a rebuild is needed\" evaluates.";
    };
    package = mkOption {
      type = types.package;
      readOnly = true;
      default = dashboard;
      description = "The dashboard command (for keybinds).";
    };
  };

  config = mkIf cfg.enable {
    # Mod+G opens it (modules/window-manager keymap)
    home.packages = [ dashboard ];
  };
}
