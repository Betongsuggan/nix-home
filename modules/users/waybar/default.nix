{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.waybar;
  theme = import ../theming/theme.nix { };
  mediaPlayerCtl = "${pkgs.playerctl}/bin/playerctl";
  mediaPlayerCtld = "${pkgs.playerctl}/bin/playerctld";

  jsonOutput = name: { pre ? "", text ? "", tooltip ? "", alt ? "", class ? "", percentage ? "" }: "${pkgs.writeShellScriptBin "waybar-${name}" ''
    set -euo pipefail
    ${pre}
    ${pkgs.jq}/bin/jq -cn \
      --arg text "${text}" \
      --arg tooltip "${tooltip}" \
      --arg alt "${alt}" \
      --arg class "${class}" \
      --arg percentage "${percentage}" \
      '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
  ''}/bin/waybar-${name}";
in {
  options.br.waybar = {
    enable = mkEnableOption "Enable Waybar";

  };

  config = mkIf cfg.enable {
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
            format = " {usage}%";
            on-click = "";
          };

          "custom/gpu" = {
            interval = 5;
            return-type = "json";
            exec = jsonOutput "gpu" {
              text = "$(cat /sys/class/drm/card0/device/gpu_busy_percent)";
              tooltip = "GPU Usage";
            };
            format = "力 {}%";
            on-click = "";
          };
          memory = {
            format = " {}%";
            interval = 5;
            on-click = "";
          };
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "  0%";
            format-icons = {
              headphone = "";
              headset = "";
              portable = "";
              default = [ "" "" "" ];
            };
            on-click = "pavucontrol";
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "零";
              deactivated = "鈴";
            };
          };
          battery = {
            bat = "BAT0";
            interval = 10;
            format-icons = [ "" "" "" "" "" "" "" "" "" "" ];
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            onclick = "";
          };
          "sway/window" = {
            max-length = 20;
          };
          network = {
            interval = 3;
            format-wifi = " {essid}";
            format-ethernet = " Connected";
            format-disconnected = "";
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              Up: {bandwidthUpBits}
              Down: {bandwidthDownBits}'';
            on-click = "${pkgs.alacritty}/bin/alacritty --command nmtui-connect";
          };
          "custom/menu" = {
            return-type = "json";
            exec = jsonOutput "menu" {
              text = "";
              tooltip = ''$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f2)'';
            };
            on-click = "${pkgs.wofi}/bin/wofi -S drun -x 10 -y 10 -W 25% -H 60%";
          };
          "custom/hostname" = {
            exec = "echo $USER@$(hostname)";
            on-click = "alacritty";
          };
          "custom/currentplayer" = {
            interval = 2;
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
              "Celluloid" = " ";
              "spotify" = " 阮";
              "ncspot" = " 阮";
              "qutebrowser" = "爵";
              "firefox" = " ";
              "discord" = " ﭮ ";
              "sublimemusic" = " ";
              "kdeconnect" = " ";
            };
            on-click = "${mediaPlayerCtld} shift";
            on-click-right = "${mediaPlayerCtld} unshift";
          };
          "custom/player" = {
            exec-if = "${mediaPlayerCtl} status";
            exec = ''${mediaPlayerCtl} metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
            return-type = "json";
            interval = 2;
            max-length = 30;
            format = "{icon} {}";
            format-icons = {
              "Playing" = "契";
              "Paused" = " ";
              "Stopped" = "栗";
            };
            on-click = "${mediaPlayerCtl} play-pause";
          };
        };
      };

      style = ''
        * {
          font-family: ${theme.font.name}, ${theme.font.style};
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
          background-color: ${theme.colors.thirdText};
          color: ${theme.colors.background};
          margin-top: 2;
          margin-bottom: 2;
          border-radius: 10px;
        }

        .modules-left {
          padding-right: 15px;
          margin-left: 0px;
          background-color: ${theme.colors.thirdText};
          color: ${theme.colors.background};
          margin-top: 2;
          margin-bottom: 2;
          border-radius: 10px;
        }

        window#waybar.bottom {
          opacity: 0.90;
          background-color: ${theme.colors.background};
          border: 2px solid ${theme.colors.border};
          border-radius: 10px;
        }

        window#waybar {
          color: ${theme.colors.thirdText};
        }

        #workspaces button {
          background-color: ${theme.colors.background};
          color: ${theme.colors.thirdText};
          margin-top: 4;
          margin-bottom: 4;
          padding-top: 0px;
          padding-bottom: 0px;
          padding-left: 4px;
          padding-right: 4px;
        }

        #workspaces button.hidden {
          background-color: ${theme.colors.background};
          color: ${theme.colors.blue};
        }

        #workspaces button.focused,
        #workspaces button.active {
          background-color: ${theme.colors.secondaryText};
          color: ${theme.colors.background};
        }

        #custom-menu {
          background-color: ${theme.colors.utilityText};
          color: ${theme.colors.background};
          padding-left: 15px;
          padding-right: 15px;
          margin-left: 0;
          margin-top: -2;
          margin-bottom: -4;
          border-radius: 10px;
        }

        #custom-hostname {
          background-color: ${theme.colors.utilityText};
          color: ${theme.colors.background};
          padding-left: 15px;
          padding-right: 15px;
          margin-right: 0;
          margin-top: -2;
          margin-bottom: -4;
          border-radius: 10px;
        }

        #tray {
          color: ${theme.colors.background};
        }
      '';
    };
  };
}
