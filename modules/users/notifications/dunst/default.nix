{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.notifications;

in {
  options.notifications.dunst = {
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional dunst configuration (merged with defaults)";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "dunst") {
    # Auto-enable launcher for dmenu functionality
    launcher.enable = mkDefault true;

    services.dunst = {
      enable = true;
      iconTheme = {
        name = "Papirus-Light";
        package = pkgs.papirus-icon-theme;
        size = "24x24";
      };
      settings = mkMerge [
        {
          global = {
            layer = "overlay";
            follow = "keyboard";
            markup = "full";
            dmenu = config.launcher.dmenu {};
            show_indicators = false;
            font = "${config.theme.font.name} ${builtins.toString config.theme.font.size}";
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
            inherit (config.theme.colors.primary) background foreground;
            highlight = config.theme.colors.normal.red;
            frame_color = config.theme.colors.bright.black;
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
        }
        cfg.dunst.settings
      ];
    };
  };
}