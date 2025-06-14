{ config, lib, pkgs, inputs, ... }:
with lib;

let
  controls = import ./controls { inherit pkgs; };
in
{
  options.hyprland = {
    enable = mkEnableOption "Enable Hyprland";

    monitorResolutions = mkOption {
      description = "Monitor resolutions";
      type = types.listOf types.str;
      default = [ ",preferred,auto,1" ];
    };
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
        controls.mediaPlayer
        controls.volume
        controls.brightness
        controls.wifi
        controls.utils.time
        controls.utils.workspaces
        controls.utils.battery
        controls.utils.system
        controls.utils.autoScreenRotation
        wofi-bluetooth
        swaylock-fancy
        grim
        slurp
        hyprpaper
        wl-clipboard
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          monitor = config.hyprland.monitorResolutions;

          cursor = {
            enable_hyprcursor = false;
          };

          "$mod" = "SUPER";
          "$modShift" = "SUPER_SHIFT";
          "$modCtrl" = "SUPER_CTRL";

          exec-once = [
            "waybar"
            "hyprpaper"
            "auto-screen-rotation"
            "${pkgs.touchegg}/bin/touchegg"
            "[workspace 1] firefox"
            ''[workspace 2] alacritty -e zellij attach --create "Bits Development"''
            ''[workspace 3] alacritty -e zellij attach --create "Nix Home"''
            "[workspace 9] slack"
          ];

          general = {
            "col.active_border" = ''rgb(${lib.strings.removePrefix "#" config.theme.colors.border-light})'';
          };

          dwindle = {
            force_split = 2;
          };

          decoration = {
            rounding = 5;
          };

          bind = [
            "$modShift, b, exec, hyprctl keyword input:kb_variant \"\""
            "$modShift, c, exec, hyprctl keyword input:kb_variant colemak"
            "$mod, RETURN, exec, ${pkgs.alacritty}/bin/alacritty"
            "$mod, f, fullscreen"
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
            "$mod, c, exec, wofi-bluetooth"
            "$mod, o, exec, ${pkgs.wofi}/bin/wofi --show drun"
            "$mod, d, exec, walker"

            ''$modShift, p, exec, ${pkgs.grim}/bin/grim -g "$(slurp)" ~/media/images/$(date -Iseconds).png''
            "$modShift, x, exec, ${pkgs.swaylock-fancy}/bin/swaylock-fancy"


            # Media control
            ", XF86AudioPlay, exec, media-player play"
            ", XF86AudioNext, exec, media-player next"
            ", XF86AudioPrev, exec, media-player previous"
          ] ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList
              (
                x:
                let
                  ws =
                    let
                      c = (x + 1) / 10;
                    in
                    builtins.toString (x + 1 - (c * 10));
                in
                [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$modShift, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
                ]
              )
              10)
          );
          binds = {
            movefocus_cycles_fullscreen = true;
          };
          binde = [
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
            kb_layout = "us";
            kb_variant = "colemak";
            kb_options = "caps:escape,compose:ralt";
            resolve_binds_by_sym = 1;
            #touchdevice = {
            #  output = "eDP-1"
            #};
          };
        };
      };
    };
  };
}
