{ config, lib, pkgs, ... }:
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

    autostartApps = mkOption {
      description = "Applications to autostart with exec-once, with optional workspace assignment";
      type = types.attrsOf (types.nullOr (types.submodule {
        options = {
          command = mkOption {
            type = types.str;
            description = "Command to execute";
            example = "firefox";
          };

          workspace = mkOption {
            type = types.nullOr types.int;
            description = "Workspace number to launch the application in (null for no specific workspace)";
            default = null;
            example = 1;
          };
        };
      }));
      default = { };
    };
  };

  config = mkIf config.hyprland.enable {
    programs.hyprland.enable = true;

    # Multi-gestures
    services.touchegg.enable = true;

    home-manager.users.${config.user} = {
      home = {
        pointerCursor = {
          inherit (config.theme.cursor) name package;
          hyprcursor = {
            enable = true;
            inherit (config.theme.cursor) size;
          };
        };
        packages = with pkgs; [
          controls.mediaPlayer
          controls.volume
          controls.brightness
          controls.utils.time
          controls.utils.workspaces
          controls.utils.battery
          controls.utils.system
          controls.utils.autoScreenRotation
          swaylock-fancy
          grim
          slurp
          wl-clipboard
        ];
      };

      services.hyprpaper = {
        enable = true;
        settings = {
          preload = "${config.theme.wallpaper}";
          wallpaper = ",${config.theme.wallpaper}";
          splash = false;
        };
      };

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
            # Common start applications
          ] ++ builtins.concatLists (builtins.attrValues (builtins.mapAttrs
            (name: app:
              if app == null then [ ]
              else
                let
                  # Autostart applications on provided worspace
                  workspacePrefix = if app.workspace != null then "[workspace ${toString app.workspace}] " else "";
                in
                [ "${workspacePrefix}${app.command}" ]
            )
            config.hyprland.autostartApps
          ));

          general = {
            "col.active_border" = ''rgb(${lib.strings.removePrefix "#" config.theme.colors.primary.foreground})'';
          };

          dwindle = {
            force_split = 2;
          };

          decoration = {
            rounding = 5;
          };

          bind = [
            ### Keyboard layouts
            # Qwerty
            "$modShift, b, exec, hyprctl keyword input:kb_variant \"\""

            # Colemak
            "$modShift, c, exec, hyprctl keyword input:kb_variant colemak"

            ### Applications
            # Terminal
            "$mod, RETURN, exec, ${pkgs.alacritty}/bin/alacritty"

            # Lock screen
            "$modShift, x, exec, ${pkgs.swaylock-fancy}/bin/swaylock-fancy"

            # Print screen
            ''$modShift, p, exec, ${pkgs.grim}/bin/grim -g "$(slurp)" ~/media/images/$(date -Iseconds).png''

            ### Screen handling
            # Forcus navigation
            "$mod, h, movefocus, l"
            "$mod, l, movefocus, r"
            "$mod, k, movefocus, u"
            "$mod, j, movefocus, d"

            # Move application in screen
            "$modShift, h, movewindow, l"
            "$modShift, l, movewindow, r"
            "$modShift, k, movewindow, u"
            "$modShift, j, movewindow, d"

            # Fullscreen application
            "$mod, f, fullscreen"

            # Kill application
            "$modShift, q, killactive,"

            ### Notifiers
            # Current media playback
            "$mod, m, exec, media-player status"

            # Battery status
            "$mod, b, exec, battery-notifier"

            # System resources, e.g. cpu, mem, storage
            "$mod, SPACE, exec, system-notifier"

            # Workspace information
            "$mod, w, exec, workspace-notifier"

            # Clock
            "$mod, t, exec, time-notifier"

            ### Launchers
            # Emojis
            "$mod, e, exec, ${pkgs.unstable.walker}/bin/walker --modules=emojis"

            # Wifi
            "$mod, u, exec, iwmenu --launcher walker --spaces 2"

            # Bluetooth
            "$mod, z, exec, bzmenu --launcher walker --spaces 2"

            # Websearch
            "$mod, d, exec, ${pkgs.unstable.walker}/bin/walker --modules=websearch"

            # Applications
            "$mod, o, exec, ${pkgs.unstable.walker}/bin/walker --modules=applications"
            # Clipboard
            "$mod, c, exec, ${pkgs.unstable.walker}/bin/walker --modules=clipboard"

            # AI
            "$mod, a, exec, ${pkgs.unstable.walker}/bin/walker --autoselect --modules=ai"

            ### Control
            # Media
            ", XF86AudioPlay, exec, media-player play"
            "$mod, s, exec, media-player play"
            ", XF86AudioNext, exec, media-player next"
            "$mod, n, exec, media-player next"
            ", XF86AudioPrev, exec, media-player previous"
            "$mod, p, exec, media-player previous"
          ] ++ (
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
                  # Move focus to workspace x
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  # Move focused application to workspace x
                  "$modShift, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
                ]
              )
              10)
          );
          binds = {
            movefocus_cycles_fullscreen = true;
          };
          binde = [
            ### Controls
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
            touchdevice = {
              output = "eDP-1";
            };
          };
        };
      };
    };
  };
}
