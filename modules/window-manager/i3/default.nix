{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  mod = "Mod4";

  wmLib = import ../lib.nix { inherit lib; };

  # my.window-manager.monitors as one xrandr call (unlisted outputs untouched)
  xrandrArgs =
    m:
    if !m.enable then
      "--output ${m.name} --off"
    else
      concatStringsSep " " (
        [ "--output ${m.name}" ]
        ++ (
          if m.mode == null then
            [ "--auto" ]
          else
            [ "--mode ${toString m.mode.width}x${toString m.mode.height}" ]
            ++ optional (m.mode.refresh != null) "--rate ${wmLib.fmtNum m.mode.refresh}"
        )
        ++ optional (m.position != null) "--pos ${toString m.position.x}x${toString m.position.y}"
        ++ optional (m.scale != 1) "--scale ${wmLib.fmtNum m.scale}x${wmLib.fmtNum m.scale}"
      );
  xrandrCommand =
    "${pkgs.xrandr}/bin/xrandr "
    + concatMapStringsSep " " xrandrArgs (wmLib.outputList config.my.window-manager.monitors);

in
{
  options.my.window-manager.i3 = {
    enable = mkEnableOption "Enable I3 window manager";
  };

  config = mkIf config.my.window-manager.i3.enable {

    services.network-manager-applet.enable = true;

    home.packages = with pkgs; [
      feh
      brightnessctl
      i3lock-fancy-rapid
    ];

    # Configure keyboard layout and compose key for X11
    home.keyboard = {
      layout = "us";
      variant = "colemak";
      options = [
        "caps:escape"
        "compose:${config.my.window-manager.composeKey}"
      ];
    };

    xsession.windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      config = {
        startup = [
          {
            command = xrandrCommand;
            always = false;
            notification = false;
          }
          {
            command = "systemctl --user restart polybar.service";
            always = true;
            notification = false;
          }
          {
            command = "systemctl --user restart picom.service";
            always = true;
            notification = false;
          }
          {
            command = "nm-applet";
            always = true;
            notification = false;
          }
          {
            command = "blueman-applet";
            always = true;
            notification = false;
          }
          {
            command = "feh --bg-center ${config.my.theming.wallpaper}";
            always = false;
            notification = false;
          }
        ]
        ++ (builtins.map
          (app: {
            command =
              if app.workspace != null then
                "i3-msg 'workspace ${toString app.workspace}; exec ${app.command}'"
              else
                app.command;
            always = false;
            notification = false;
          })
          (builtins.filter (app: app != null) (builtins.attrValues config.my.window-manager.autostartApps))
        );

        modifier = mod;

        fonts = with config.my.theming.font; {
          inherit style size;
          names = [ name ];
        };

        # The shared keymap (my.window-manager.keybinds) on top of i3's defaults
        keybindings = lib.mkOptionDefault (wmLib.i3Keybindings "i3" mod config.my.window-manager.keybinds);

        bars = [ ];

        gaps = {
          bottom = 10;
          top = 10;
          horizontal = 10;
          vertical = 10;
          outer = 10;
          inner = 10;
          left = 10;
          right = 10;
          smartGaps = true;
        };

        colors = with config.my.theming.colors; {
          background = "${primary.background}";

          focused = {
            border = "${normal.blue}";
            background = "${normal.blue}";
            text = "${bright.black}";
            indicator = "${normal.magenta}";
            childBorder = "${bright.black}";
          };

          unfocused = {
            border = "${bright.black}";
            background = "${bright.black}";
            text = "${normal.white}";
            indicator = "${normal.magenta}";
            childBorder = "${bright.black}";
          };

          focusedInactive = {
            border = "${bright.black}";
            background = "${bright.black}";
            text = "${bright.black}";
            indicator = "${normal.magenta}";
            childBorder = "${bright.black}";
          };

          urgent = {
            border = "${normal.red}";
            background = "${normal.red}";
            text = "${primary.foreground}";
            indicator = "${primary.foreground}";
            childBorder = "${primary.foreground}";
          };
        };

        window.titlebar = false;
      };
    };

    programs.i3status = {
      enable = true;
      enableDefault = false;
      general = {
        colors = true;
        interval = 5;
        color_good = "#2AA198";
        color_bad = "#586E75";
        color_degraded = "#DC322F";
      };
      modules = {
        "cpu_usage" = {
          position = 0;
          settings = {
            format = " cpu  %usage ";
          };
        };

        "cpu_temperature 1" = {
          position = 0.5;
          settings = {
            format = "%degrees °C";
          };
        };

        "disk /" = {
          position = 1;
          settings = {
            # format = " hdd %avail "
            format = " ⛁ %avail ";
          };
        };

        "volume master" = {
          position = 2;
          settings = {
            format = "♪: %volume";
            format_muted = "♪: muted (%volume)";
            device = "default";
          };
        };

        "battery all" = {
          position = 3;
          settings = {
            format = "%status %percentage";
            format_down = "No battery";

            last_full_capacity = true;

            integer_battery_capacity = true;

            status_chr = "⚡";

            status_bat = "☉";

            status_unk = "";

            status_full = "☻";

            low_threshold = 15;
            threshold_type = "time";
          };
        };

        "memory" = {
          position = 4;
          settings = {
            format = "%used | %available";
            threshold_degraded = "1G";
            format_degraded = "MEMORY < %available";
          };
        };

        "tztime local" = {
          position = 5;
          settings = {
            format = " %Y-%m-%d %H:%M:%S ";
          };
        };
      };
    };

    systemd.user.services.mpris-proxy = {
      Unit.Description = "Mpris proxy";
      Unit.After = [
        "network.target"
        "sound.target"
      ];
      Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Install.WantedBy = [ "default.target" ];
    };
  };
}
