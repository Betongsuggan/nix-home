{ config, lib, pkgs, ... }:
with lib;

let
  theme = import ../theming/theme.nix { };
in
{
  options.hyprland = {
    enable = mkEnableOption "Enable Hyprland";
  };

  config = mkIf config.hyprland.enable {
    programs.hyprland.enable = true;
    home-manager.users.${config.user} = {
      home.file.".config/hypr/hyprpaper.conf".text = ''
        preload = ~/media/images/nix-background.png
        wallpaper = ,~/media/images/nix-background.png
        splash = false
      '';
      home.packages = with pkgs; [
        swaylock-fancy
        grim
        slurp
        hyprpaper
        wl-clipboard
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          monitor = [
            ",preferred,auto,1"
          ];

          "$mod" = "SUPER";
          "$modShift" = "SUPER_SHIFT";

          exec-once = [
            "waybar"
            "hyprpaper"
          ];

          general = {
            "col.active_border" = ''rgb(${lib.strings.removePrefix "#" theme.colors.utilityText})'';
          };

          decoration = {
            rounding = 5;
          };

          bind = [

            "$mod, RETURN, exec, ${pkgs.alacritty}/bin/alacritty"
            "$mod, f, fullscreen,"
            "$modShift, q, killactive,"

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
            "$modShift, x, exec, ${pkgs.swaylock-fancy}/bin/swaylock-fancy"

            # Brightness
            ", XF86MonBrightnessDown, exec, light -U 10"
            ", XF86MonBrightnessUp,  exec, light -A 10"

            # Volume
            ", XF86AudioRaiseVolume, exec, ${pkgs.pamixer}/bin/pamixer -i 2"
            ", XF86AudioLowerVolume, exec, ${pkgs.pamixer}/bin/pamixer -d 2"
            ", XF86AudioMute, exec, ${pkgs.pamixer}/bin/pamixer -t"

            # Media control
            ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
            ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
            ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
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

          misc = {
            disable_splash_rendering = true;
          };

          input = {
            kb_layout = "us,us";
            kb_variant = "colemak,";
            kb_options = "caps:escape,compose:ralt,grp:shifts_toggle";
          };
        };
      };
    };
  };
}
