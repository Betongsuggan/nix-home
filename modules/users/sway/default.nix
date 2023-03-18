{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.sway;
  theme = import ../theming/theme.nix { };
  modifier = "Mod4";
in {
  options.br.sway = {
    enable = mkEnableOption "Enable Sway";

  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      swaylock-fancy
      swayidle
      wl-clipboard
      mako
      wofi
    ];

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      config = rec {
        inherit modifier;
        terminal = "alacritty";
        menu = "wofi --show run";

        fonts = with theme.font; {
          inherit style size;
          names = [ name ];
        };

        gaps = {
          top = 6;
          horizontal = 6;
          vertical = 6;
          outer = 6;
          inner = 6;
          left = 6;
          right = 6;
        };

        bars = [
          {
            position = "bottom";
            command = "waybar";
          }
        ];

        keybindings = lib.mkOptionDefault {
          "${modifier}+o" = "exec ${pkgs.wofi}/bin/wofi --show run";
          "${modifier}+Shift+x" = "exec ${pkgs.swaylock-fancy}/bin/swaylock-fancy";
        };

        colors =  with theme.colors; {
          background = "${background}";

          focused = {
            border      = "${thirdText}";
            background  = "${thirdText}";
            text        = "${borderDark}";
            indicator   = "${purple}";
            childBorder = "${borderDark}";
          };

          unfocused = {
            border     = "${borderDark}";
            background = "${borderDark}";
            text       = "${utilityText}";
            indicator   = "${purple}";
            childBorder = "${borderDark}";
          };

          focusedInactive = {
            border     = "${borderDark}";
            background = "${borderDark}";
            text       = "${borderDark}";
            indicator   = "${purple}";
            childBorder = "${borderDark}";
          };

          urgent = {
            border     = "${alertText}";
            background = "${alertText}";
            text       = "${mainText}";
            indicator   = "${mainText}";
            childBorder = "${mainText}";
          };
        };

        window.titlebar = false;
      };
      extraConfig = ''
        input * xkb_layout "us"
        input * xkb_variant "colemak"
        input * xkb_options "caps:escape,compose:ralt"

        # Brightness
        bindsym XF86MonBrightnessDown exec light -U 10
        bindsym XF86MonBrightnessUp exec light -A 10

        # Volume
        bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
        bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
        bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'
      '';
    };
  };
}
