{ config, lib, pkgs, ... }:
with lib;

let
  mediaPlayerCtl = "${pkgs.playerctl}/bin/playerctl";
  mediaPlayerCtld = "${pkgs.playerctl}/bin/playerctld";

  jsonOutput = name:
    { pre ? "", text ? "", tooltip ? "", alt ? "", class ? "", percentage ? ""
    }:
    "${
      pkgs.writeShellScriptBin "waybar-${name}" ''
        set -euo pipefail
        ${pre}
        ${pkgs.jq}/bin/jq -cn \
          --arg text "${text}" \
          --arg tooltip "${tooltip}" \
          --arg alt "${alt}" \
          --arg class "${class}" \
          --arg percentage "${percentage}" \
          '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
      ''
    }/bin/waybar-${name}";
in {
  options.waybar = { enable = mkEnableOption "Enable Waybar"; };

  config = mkIf config.waybar.enable {
    programs.waybar = {
      enable = true;
      settings = {
        primary = {
          mode = "dock";
          layer = "top";
          height = 20;
          margin = "6";
          position = "bottom";
          modules-left = [
            "custom/menu"
            "clock"
            "cpu"
            "custom/gpu"
            "memory"
            "pulseaudio"
            "custom/player"
            "custom/currentplayer"
          ];
          modules-right = [
            "sway/workspaces"
            "sway/mode"
            "network"
            "battery"
            "tray"
            "custom/hostname"
          ];

          clock = {
            format = "{:%d/%m %H:%M}";
            tooltip-format = ''
              <big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
            on-click = "";

          };
          cpu = {
            interval = 15;
            format = " {usage}%";
            on-click = "";
          };

          "custom/gpu" = {
            interval = 30;
            return-type = "json";
            exec = jsonOutput "gpu" {
              text = "$(cat /sys/class/drm/card0/device/gpu_busy_percent)";
              tooltip = "GPU Usage";
            };
            format = "󰒋 {}%";
            on-click = "";
          };
          memory = {
            format = " {}%";
            interval = 15;
            on-click = "";
          };
          pulseaudio = {
            interval = 10;
            format = "{icon} {volume}%";
            format-muted = "  0%";
            format-icons = {
              headphone = "";
              headset = "󰋎";
              portable = "";
              default = [ "" "" "" ];
            };
            on-click = "pavucontrol";
          };
          battery = {
            bat = "BAT0";
            interval = 10;
            format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            onclick = "";
          };
          "sway/window" = { max-length = 20; };
          network = {
            interval = 10;
            format-wifi = " {essid}";
            format-ethernet = "󰛳 Connected";
            format-disconnected = "";
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              Up: {bandwidthUpBits}
              Down: {bandwidthDownBits}'';
            on-click =
              "${pkgs.alacritty}/bin/alacritty --command nmtui-connect";
          };
          "custom/menu" = {
            interval = 1000;
            return-type = "json";
            exec = jsonOutput "menu" {
              text = "";
              tooltip =
                ''$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f2)'';
            };
            on-click =
              "${pkgs.wofi}/bin/wofi -S drun -x 10 -y 10 -W 25% -H 60%";
          };
          "custom/hostname" = {
            interval = 1000;
            exec = "echo $USER@$(hostname)";
            on-click = "alacritty";
          };
          "custom/currentplayer" = {
            interval = 10;
            return-type = "json";
            exec = jsonOutput "currentplayer" {
              pre = ''
                player="$(${mediaPlayerCtl} status -f "{{playerName}}" 2>/dev/null || echo "No player active" | cut -d '.' -f1)"
                count="$(${mediaPlayerCtl} -l | wc -l)"
                if ((count > 1)); then
                  more=" +$((count - 1))"
                else
                  more=""
                fi
              '';
              alt = "$player";
              tooltip = "$player ($count available)";
              text = "$more";
            };
            format = "{icon}{}";
            format-icons = {
              "No player active" = " ";
              "Celluloid" = " ";
              "spotify" = "  ";
              "firefox" = " ";
              "discord" = " 󰙯 ";
              "sublimemusic" = " ";
            };
            on-click = "${mediaPlayerCtld} shift";
            on-click-right = "${mediaPlayerCtld} unshift";
          };
          "custom/player" = {
            exec-if = "${mediaPlayerCtl} status";
            exec = ''
              ${mediaPlayerCtl} metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
            return-type = "json";
            interval = 10;
            max-length = 60;
            format = "{icon} {}";
            format-icons = {
              "Playing" = "󰏤 ";
              "Paused" = "󰐊 ";
              "Stopped" = "󰐊 ";
            };
            on-click = "${mediaPlayerCtl} play-pause";
          };
        };
      };

      style = ''
        * {
          font-family: ${config.theme.font.name}, ${theme.font.style};
          font-size: 10pt;
        }

        .modules-left * {
          margin-right: 4px;
          margin-left: 4px;
        }

        .modules-right * {
          margin-right: 4px;
          margin-left: 4px;
        }

        .modules-right {
          margin-right: 0px;
          padding-left: 15px;
          background-color: ${config.theme.colors.thirdText};
          color: ${config.theme.colors.background};
          margin-top: 2;
          margin-bottom: 2;
          border-radius: ${config.theme.cornerRadius};
        }

        .modules-left {
          padding-right: 15px;
          margin-left: 0px;
          background-color: ${config.theme.colors.thirdText};
          color: ${config.theme.colors.background};
          margin-top: 2;
          margin-bottom: 2;
          border-radius: ${config.theme.cornerRadius};
        }

        window#waybar.bottom {
          opacity: 0.90;
          background-color: ${config.theme.colors.background};
          border: 2px solid ${config.theme.colors.border};
          border-radius: ${config.theme.cornerRadius};
        }

        window#waybar {
          color: ${config.theme.colors.thirdText};
        }

        #workspaces button {
          background-color: ${config.theme.colors.background};
          color: ${config.theme.colors.thirdText};
          margin-top: 4;
          margin-bottom: 4;
          padding-top: 0px;
          padding-bottom: 0px;
          padding-left: 4px;
          padding-right: 4px;
        }

        #workspaces button.hidden {
          background-color: ${config.theme.colors.background};
          color: ${config.theme.colors.blue};
        }

        #workspaces button.focused,
        #workspaces button.active {
          background-color: ${config.theme.colors.secondaryText};
          color: ${config.theme.colors.background};
        }

        #custom-menu {
          background-color: ${config.theme.colors.utilityText};
          color: ${config.theme.colors.background};
          padding-left: 15px;
          padding-right: 15px;
          margin-left: 0;
          margin-top: -2;
          margin-bottom: -4;
          border-radius: ${config.theme.cornerRadius};
        }

        #custom-hostname {
          background-color: ${config.theme.colors.utilityText};
          color: ${config.theme.colors.background};
          padding-left: 15px;
          padding-right: 15px;
          margin-right: 0;
          margin-top: -2;
          margin-bottom: -4;
          border-radius: ${config.theme.cornerRadius};
        }

        #tray {
          color: ${config.theme.colors.background};
        }
      '';
    };
  };
}
