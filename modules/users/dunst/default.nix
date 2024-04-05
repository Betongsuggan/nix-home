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
    environment.systemPackages = with pkgs; [
      tela-icon-theme 
    ];
    home-manager.users.${config.user} = {
      services.dunst = {
        enable = true;
        iconTheme = {
          name = "Tela-black";
          package = pkgs.tela-icon-theme;
          size = "scalable";
        };
        settings = {
          global = {
            follow = "keyboard";
            markup = "full";
            dmenu = "${pkgs.wofi} --dmenu";
            format = "<b>%a</b>\\n%s\\n\\n%b";
            width = "(0,300)";
            offset = "30x50";
            corner_radius = 5;
            separator_height = 5;
            frame_width = 3;
            gap_size = 4;
            layer = "overlay";
            font = "${theme.font.name} ${theme.font.sizeStr}";
            mouse_left = "do_action";
            mouse_middle = "context";
            mouse_right = "close_current";
            background = theme.colors.thirdText;
            foreground = theme.colors.background;
            frame_color = theme.colors.borderDark;
          };

          urgency_low.timeout = 10;
          urgency_normal.timeout = 30;
          urgency_critical.timeout = 300;
        };
      };
    }; 
  };
}
  
