{ config, lib, pkgs, ... }:
with lib;
{
  options.dunst = {
    enable = mkEnableOption "Enable Dunst notification daemon";
  };

  # TODO Notifications
  # Connect/disconnect wifi. Show wifi/network info
  # Low battery notification. Charger connected/disconnected notification. show battery status.
  # Show system performance, e.g. cpu, memory, storage etc.
  # Mediaplayer started stopped, changed song?

  config = mkIf config.dunst.enable {
    environment.systemPackages = with pkgs; [
      papirus-icon-theme 
    ];
    home-manager.users.${config.user} = {
      services.dunst = {
        enable = true;
        iconTheme = {
          name = "Papirus-Light";
          package = pkgs.papirus-icon-theme;
          size = "24x24";
        };
        settings = {
          global = {
            layer = "overlay";
            follow = "keyboard";
            markup = "full";
            dmenu = "${pkgs.wofi}/bin/wofi --dmenu";
            show_indicators = false;

            font = "${theme.font.name} ${theme.font.sizeStr}";
            format = "<b>%a</b>\\n%s\\n\\n%b";
            width = "(0,400)";
            offset = "40x40";
            corner_radius = 5;
            separator_height = 5;
            frame_width = 3;
            gap_size = 4;
            vertical_alignment = "top";

            progress_bar_corner_radius = 4;

            mouse_left = "context";
            mouse_middle = "context";
            mouse_right = "close_current";

            background  = config.theme.colors.background-dark;
            foreground  = config.theme.colors.text-light;
            highlight   = config.theme.colors.red-light;
            frame_color = config.theme.colors.border-light;
          };
          slack = {
            desktop_entry = "Slack";
            new_icon = "/run/current-system/sw/share/icons/Papirus/24x24/apps/slack.svg";
          };
          discord = {
            desktop_entry = "Discord";
            skip_display = true;
          };

          urgency_low.timeout = 10;
          urgency_normal.timeout = 30;
          urgency_critical.timeout = 300;
        };
      };
    }; 
  };
}
  
