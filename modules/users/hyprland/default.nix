{ config, lib, pkgs, inputs, ... }:
with lib;

let
  theme = import ../theming/theme.nix { };
  utils = import ./utilNotifications.nix { inherit pkgs; };
  wifiControl = import ./wifiControls.nix { inherit pkgs; };
  mediaPlayer = import ./mediaPlayerControls.nix { inherit pkgs; };
  volumeControl = import ./volumeControls.nix { inherit pkgs; };
  brightnessControl = import ./brightnessControls.nix { inherit pkgs; };
in
{
  options.hyprland = {
    enable = mkEnableOption "Enable Hyprland";
  };

  config = mkIf config.hyprland.enable {
    programs.hyprland.enable = true;
    services.touchegg.enable = true;
    home-manager.users.${config.user} = {
      home.file.".config/hypr/hyprpaper.conf".text = ''
        preload = ~/media/images/nix-background.png
        wallpaper = ,~/media/images/nix-background.png
        splash = false
      '';
      home.packages = with pkgs; [
        mediaPlayer
        volumeControl
        brightnessControl
        wifiControl
        utils.time
        utils.workspaces
        utils.battery
        utils.system
        utils.autoScreenRotation
        swaylock-fancy
        grim
        slurp
        hyprpaper
        wl-clipboard
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        settings = {
          monitor = [
            "eDP-1,preferred,auto,1"
          ];

          "$mod" = "SUPER";
          "$modShift" = "SUPER_SHIFT";

          exec-once = [
            "waybar"
            "hyprpaper"
            "auto-screen-rotation"
            "${pkgs.touchegg}/bin/touchegg"
          ];

          general = {
            "col.active_border" = ''rgb(${lib.strings.removePrefix "#" theme.colors.border-light})'';
          };

          dwindle = {
            force_split = 2;
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

            "$mod, s, exec, media-player play"
            "$mod, n, exec, media-player next"
            "$mod, p, exec, media-player previous"

            "$mod, SPACE, exec, system-notifier"
            "$mod, m, exec, media-player status"
            "$mod, b, exec, battery-notifier"
            "$mod, w, exec, workspace-notifier"
            "$mod, t, exec, time-notifier"
            "$mod, e, exec, ${pkgs.wofi-emoji}/bin/wofi-emoji"
            "$mod, u, exec, wifi-control"
            "$mod, o, exec, ${pkgs.wofi}/bin/wofi --show drun"
            ''$modShift, p, exec, ${pkgs.grim}/bin/grim -g "$(slurp)" ~/media/images/$(date -Iseconds)''
            "$modShift, x, exec, ${pkgs.swaylock-fancy}/bin/swaylock-fancy"


            # Media control
            ", XF86AudioPlay, exec, media-player play"
            ", XF86AudioNext, exec, media-player next"
            ", XF86AudioPrev, exec, media-player previous"
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
                  "$modShift, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );
          binde=[
            # Brightness
            ", XF86MonBrightnessUp,  exec, brightness-control -i 10"
            ", XF86MonBrightnessDown, exec, brightness-control -d 10"

            # Volume
            ", XF86AudioRaiseVolume, exec, volume-control -i 2"
            ", XF86AudioLowerVolume, exec, volume-control -d 2"
            ", XF86AudioMute, exec, volume-control -m"
          ];

          misc = {
            disable_splash_rendering = true;
            vfr = true;
          };

          gestures = {
            workspace_swipe = true;
          };

          input = {
            kb_layout = "us,us";
            kb_variant = "colemak,";
            kb_options = "caps:escape,compose:ralt,grp:shifts_toggle";
            touchdevice = {
              output = "eDP-1";
            };
          };
        };
      };
    };
  };
}
