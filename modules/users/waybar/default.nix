{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.waybar;
in {
  options.br.waybar = {
    enable = mkEnableOption "Enable Waybar";

  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      #settings = {
      #  primary = {
      #    mode = "dock";
      #    layer = "top";
      #    height = 40;
      #    margin = "6";
      #    position = "bottom";
      #    #output = builtins.map (m: m.name) (builtins.filter (m: m.hasBar) config.monitors);
      #    modules-left = [
      #      "custom/menu"
      #      #"custom/currentplayer"
      #      #"custom/player"
      #    ];
      #    modules-center = [
      #      "cpu"
      #      "custom/gpu"
      #      "memory"
      #      "clock"
      #      "pulseaudio"
      #      #"custom/unread-mail"
      #      "custom/gammastep"
      #      #"custom/gpg-agent"
      #    ];
      #    modules-right = [
      #      #"custom/gamemode"
      #      "network"
      #      #"custom/tailscale-ping"
      #      "battery"
      #      "tray"
      #      "custom/hostname"
      #    ];

      #    clock = {
      #      format = "{:%d/%m %H:%M}";
      #      tooltip-format = ''
      #        <big>{:%Y %B}</big>
      #        <tt><small>{calendar}</small></tt>'';
      #      on-click = calendar;
      #    };
      #    cpu = {
      #      format = "   {usage}%";
      #      on-click = systemMonitor;
      #    };
      #    "custom/gpu" = {
      #      interval = 5;
      #      return-type = "json";
      #      exec = jsonOutput "gpu" {
      #        text = "$(cat /sys/class/drm/card0/device/gpu_busy_percent)";
      #        tooltip = "GPU Usage";
      #      };
      #      format = "力  {}%";
      #      on-click = systemMonitor;
      #    };
      #    memory = {
      #      format = "  {}%";
      #      interval = 5;
      #      on-click = systemMonitor;
      #    };
      #    pulseaudio = {
      #      format = "{icon}  {volume}%";
      #      format-muted = "   0%";
      #      format-icons = {
      #        headphone = "";
      #        headset = "";
      #        portable = "";
      #        default = [ "" "" "" ];
      #      };
      #      on-click = pavucontrol;
      #    };
      #    idle_inhibitor = {
      #      format = "{icon}";
      #      format-icons = {
      #        activated = "零";
      #        deactivated = "鈴";
      #      };
      #    };
      #    battery = {
      #      bat = "BAT0";
      #      interval = 10;
      #      format-icons = [ "" "" "" "" "" "" "" "" "" "" ];
      #      format = "{icon} {capacity}%";
      #      format-charging = " {capacity}%";
      #      onclick = "";
      #    };
      #    "sway/window" = {
      #      max-length = 20;
      #    };
      #    network = {
      #      interval = 3;
      #      format-wifi = "   {essid}";
      #      format-ethernet = " Connected";
      #      format-disconnected = "";
      #      tooltip-format = ''
      #        {ifname}
      #        {ipaddr}/{cidr}
      #        Up: {bandwidthUpBits}
      #        Down: {bandwidthDownBits}'';
      #      on-click = "";
      #    };
      #    #"custom/tailscale-ping" = {
      #    #  interval = 2;
      #    #  return-type = "json";
      #    #  exec =
      #    #    let
      #    #      inherit (builtins) concatStringsSep attrNames;
      #    #      hosts = attrNames outputs.nixosConfigurations;
      #    #      homeMachine = "merope";
      #    #      remoteMachine = "alcyone";
      #    #    in
      #    #    jsonOutput "tailscale-ping" {
      #    #      # Build variables for each host
      #    #      pre = ''
      #    #        set -o pipefail
      #    #        ${concatStringsSep "\n" (map (host: ''
      #    #          ping_${host}="$(timeout 2 ping -c 1 -q ${host} 2>/dev/null | tail -1 | cut -d '/' -f5 | cut -d '.' -f1)ms" || ping_${host}="Disconnected"
      #    #        '') hosts)}
      #    #      '';
      #    #      # Access a remote machine's and a home machine's ping
      #    #      text = "  $ping_${remoteMachine} /  $ping_${homeMachine}";
      #    #      # Show pings from all machines
      #    #      tooltip = concatStringsSep "\n" (map (host: "${host}: $ping_${host}") hosts);
      #    #    };
      #    #  format = "{}";
      #    #  on-click = "";
      #    #};
      #    "custom/menu" = {
      #      return-type = "json";
      #      exec = jsonOutput "menu" {
      #        text = "";
      #        tooltip = ''$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f2)'';
      #      };
      #      on-click = "${wofi} -S drun -x 10 -y 10 -W 25% -H 60%";
      #    };
      #    "custom/hostname" = {
      #      exec = "echo $USER@$(hostname)";
      #      on-click = terminal;
      #    };
      #    "custom/gammastep" = {
      #      interval = 5;
      #      return-type = "json";
      #      exec = jsonOutput "gammastep" {
      #        pre = ''
      #          if unit_status="$(${systemctl} --user is-active gammastep)"; then
      #            status="$unit_status ($(${journalctl} --user -u gammastep.service -g 'Period: ' | tail -1 | cut -d ':' -f6 | xargs))"
      #          else
      #            status="$unit_status"
      #          fi
      #        '';
      #        alt = "\${status:-inactive}";
      #        tooltip = "Gammastep is $status";
      #      };
      #      format = "{icon}";
      #      format-icons = {
      #        "activating" = " ";
      #        "deactivating" = " ";
      #        "inactive" = "? ";
      #        "active (Night)" = " ";
      #        "active (Nighttime)" = " ";
      #        "active (Transition (Night)" = " ";
      #        "active (Transition (Nighttime)" = " ";
      #        "active (Day)" = " ";
      #        "active (Daytime)" = " ";
      #        "active (Transition (Day)" = " ";
      #        "active (Transition (Daytime)" = " ";
      #      };
      #      on-click = "${systemctl} --user is-active gammastep && ${systemctl} --user stop gammastep || ${systemctl} --user start gammastep";
      #    };
      #    #"custom/currentplayer" = {
      #    #  interval = 2;
      #    #  return-type = "json";
      #    #  exec = jsonOutput "currentplayer" {
      #    #    pre = ''
      #    #      player="$(${playerctl} status -f "{{playerName}}" 2>/dev/null || echo "No player active" | cut -d '.' -f1)"
      #    #      count="$(${playerctl} -l | wc -l)"
      #    #      if ((count > 1)); then
      #    #        more=" +$((count - 1))"
      #    #      else
      #    #        more=""
      #    #      fi
      #    #    '';
      #    #    alt = "$player";
      #    #    tooltip = "$player ($count available)";
      #    #    text = "$more";
      #    #  };
      #    #  format = "{icon}{}";
      #    #  format-icons = {
      #    #    "No player active" = " ";
      #    #    "Celluloid" = " ";
      #    #    "spotify" = " 阮";
      #    #    "ncspot" = " 阮";
      #    #    "qutebrowser" = "爵";
      #    #    "firefox" = " ";
      #    #    "discord" = " ﭮ ";
      #    #    "sublimemusic" = " ";
      #    #    "kdeconnect" = " ";
      #    #  };
      #    #  on-click = "${playerctld} shift";
      #    #  on-click-right = "${playerctld} unshift";
      #    #};
      #    #"custom/player" = {
      #    #  exec-if = "${playerctl} status";
      #    #  exec = ''${playerctl} metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
      #    #  return-type = "json";
      #    #  interval = 2;
      #    #  max-length = 30;
      #    #  format = "{icon} {}";
      #    #  format-icons = {
      #    #    "Playing" = "契";
      #    #    "Paused" = " ";
      #    #    "Stopped" = "栗";
      #    #  };
      #    #  on-click = "${playerctl} play-pause";
      #    #};
      #  };
      #};
      style = ./style.css;
    };
  };
}
