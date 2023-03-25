{ config, lib, pkgs, ... }:
with lib;

let
  inherit (pkgs) pamixer playerctl;
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
      sway-contrib.grimshot
      wl-clipboard
      mako
      wofi
      networkmanager_dmenu
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

        startup = [
          {
            command = "blueman-applet";
            always = false;
          }
        ];

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
          "${modifier}+x" = "exec date -Iseconds | { read date; ${pkgs.sway-contrib.grimshot}/bin/grimshot save area ~/Pictures/\${date}; }";
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
        input * xkb_layout "us,us"
        input * xkb_variant "colemak,"
        input * xkb_options "caps:escape,compose:ralt,grp:shifts_toggle"

        # Brightness
        bindsym XF86MonBrightnessDown exec light -U 10
        bindsym XF86MonBrightnessUp exec light -A 10

        # Volume
        bindsym XF86AudioRaiseVolume exec '${pamixer}/bin/pamixer -i 2'
        bindsym XF86AudioLowerVolume exec '${pamixer}/bin/pamixer -d 2'
        bindsym XF86AudioMute exec '${pamixer}/bin/pamixer -t'

        # Media control
        bindsym XF86AudioPlay exec '${playerctl}/bin/playerctl play-pause'
        bindsym XF86AudioNext exec '${playerctl}/bin/playerctl next'
        bindsym XF86AudioPrev exec '${playerctl}/bin/playerctl previous'
      '';
    };
  };
}
