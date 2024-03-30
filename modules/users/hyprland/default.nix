{ config, lib, pkgs, ... }:
with lib;

let
  inherit (pkgs) pamixer playerctl;
  theme = import ../theming/theme.nix { };
  modifier = "Mod4";
in
{
  options.hyprland = {
    enable = mkEnableOption "Enable Hyprland";
  };

  config = mkIf config.hyprland.enable {
    programs.hyprland.enable = true;
    home-manager.users.${config.user} = {
      home.file.".config/hypr/hyprpaper.conf".text = ''
        preload = ~/Pictures/nix-background.png
        wallpaper = eDP-1,~/Pictures/nix-background.png
      '';
      home.packages = with pkgs; [
        swaylock-fancy
        #grim
        #swayidle
        hyprpaper
        wl-clipboard
        mako
        networkmanager_dmenu
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        settings = rec {
          monitor = [
            ",preferred,auto,1"
          ];

          "$mod" = "SUPER";
          "$modShift" = "SUPER_SHIFT";

          exec-once = [
            "waybar"
            "bluman-applet"
          ];

          general = {
            "col.active_border" = ''rgb(${lib.strings.removePrefix "#" theme.colors.utilityText})'';
          };

          decoration = {
            rounding = 5;
          };

          bind = [

            "$mod, RETURN, exec, ${pkgs.alacritty}/bin/alacritty"
            "$modShift, q, killactive,"

            "$modShift, x, exec, ${pkgs.swaylock-fancy}/bin/swaylock-fancy"

            "$mod, h, movefocus, l"
            "$mod, l, movefocus, r"
            "$mod, k, movefocus, u"
            "$mod, j, movefocus, d"

            "$modShift, h, movewindow, l"
            "$modShift, l, movewindow, r"
            "$modShift, k, movewindow, u"
            "$modShift, j, movewindow, d"

            "$mod, o, exec, ${pkgs.wofi}/bin/wofi --show drun"
            ''$modShift, p, exec, ${pkgs.grim}/bin/grim -g "$(slurp)" ~/media/images/$(date -Iseconds)''

            # Brightness
            ", XF86MonBrightnessDown, exec, light -U 10"
            ", XF86MonBrightnessUp,  exec, light -A 10"

            # Volume
            ", XF86AudioRaiseVolume, exec, '${pamixer}/bin/pamixer -i 2'"
            ", XF86AudioLowerVolume, exec, '${pamixer}/bin/pamixer -d 2'"
            ", XF86AudioMute, exec, '${pamixer}/bin/pamixer -t'"

            # Media control
            ", XF86AudioPlay, exec, '${playerctl}/bin/playerctl play-pause'"
            ", XF86AudioNext, exec, '${playerctl}/bin/playerctl next'"
            ", XF86AudioPrev, exec, '${playerctl}/bin/playerctl previous'"
          ] ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    builtins.toString (x + 1 - (c * 10));
                in [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );

          input = {
            kb_layout = "us,us";
            kb_variant = "colemak,";
            kb_options = "caps:escape,compose:ralt,grp:shifts_toggle";
          };
        };
        #  inherit modifier;
        #  terminal = "alacritty";
        #  menu = "wofi --show drun";

        #  fonts = with theme.font; {
        #    inherit style size;
        #    names = [ name ];
        #  };

        #  startup = [
        #    {
        #      command = "blueman-applet";
        #      always = false;
        #    }
        #  ];

        #  gaps = {
        #    top = 6;
        #    horizontal = 6;
        #    vertical = 6;
        #    outer = 6;
        #    inner = 6;
        #    left = 6;
        #    right = 6;
        #  };

        #  bars = [
        #    {
        #      position = "bottom";
        #      command = "waybar";
        #    }
        #  ];

        #  keybindings = lib.mkOptionDefault {
        #    "${modifier}+o" = "exec ${pkgs.wofi}/bin/wofi --show drun";

        #    "${modifier}+Shift+x" = "exec ${pkgs.swaylock-fancy}/bin/swaylock-fancy";

        #    "${modifier}+Shift+p" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot save area ~/Pictures/$(date -Iseconds)";
        #  };

        #  input = {
        #    "*" = {
        #      tap = "enabled";
        #    };
        #  };

        #  colors = with theme.colors; {
        #    background = "${background}";

        #    focused = {
        #      border = "${thirdText}";
        #      background = "${thirdText}";
        #      text = "${borderDark}";
        #      indicator = "${purple}";
        #      childBorder = "${borderDark}";
        #    };

        #    unfocused = {
        #      border = "${borderDark}";
        #      background = "${borderDark}";
        #      text = "${utilityText}";
        #      indicator = "${purple}";
        #      childBorder = "${borderDark}";
        #    };

        #    focusedInactive = {
        #      border = "${borderDark}";
        #      background = "${borderDark}";
        #      text = "${borderDark}";
        #      indicator = "${purple}";
        #      childBorder = "${borderDark}";
        #    };

        #    urgent = {
        #      border = "${alertText}";
        #      background = "${alertText}";
        #      text = "${mainText}";
        #      indicator = "${mainText}";
        #      childBorder = "${mainText}";
        #    };
        #  };

        #  window.titlebar = false;
        #};
        #extraConfig = ''
        #  input * xkb_layout "us,us"
        #  input * xkb_variant "colemak,"
        #  input * xkb_options "caps:escape,compose:ralt,grp:shifts_toggle"

        #  # Brightness
        #  bindsym XF86MonBrightnessDown exec light -U 10
        #  bindsym XF86MonBrightnessUp exec light -A 10

        #  # Volume
        #  bindsym XF86AudioRaiseVolume exec '${pamixer}/bin/pamixer -i 2'
        #  bindsym XF86AudioLowerVolume exec '${pamixer}/bin/pamixer -d 2'
        #  bindsym XF86AudioMute exec '${pamixer}/bin/pamixer -t'

        #  # Media control
        #  bindsym XF86AudioPlay exec '${playerctl}/bin/playerctl play-pause'
        #  bindsym XF86AudioNext exec '${playerctl}/bin/playerctl next'
        #  bindsym XF86AudioPrev exec '${playerctl}/bin/playerctl previous'
        #'';
      };
    };
  };
}
