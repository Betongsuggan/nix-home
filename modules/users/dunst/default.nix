{ config, lib, pkgs, ... }:
let
  theme = import ../theming/theme.nix { };
in
with lib;
{
  options.dunst = {
    enable = mkEnableOption "Enable Dunst notification daemon";
  };

  config = mkIf config.dunst.enable {
    home-manager.users.${config.user} = {
      services.dunst = {
        enable = true;
        iconTheme = {
          name = "tela-icon-theme";
          package = pkgs.tela-icon-theme;
        };
        settings = {
          global = {
            width = "(0,300)";
            offset = "30x50";
            corner_radius = 5;
            separator_height = 5;
            frame_width = 3;
            gap_size = 4;
            layer = "overlay";
            font = "${theme.font.name} ${theme.font.sizeStr}";
            mouse_left = "context";
            mouse_right = "close_current";
            background = theme.colors.thirdText;
            foreground = theme.colors.background;
            frame_color = theme.colors.borderDark;
          };

          urgency_low.timeout = 3;
          urgency_normal.timeout = 5;
          urgency_critical.timeout = 10;
        };
      };
    }; 
  };
}
  
