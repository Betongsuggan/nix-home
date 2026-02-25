{ config, pkgs, lib, ... }:
with lib;
let
  mod = "Mod4";

  # Convert Hyprland monitor format to xrandr command
  # Hyprland: "name,resolution@refresh,position,scale"
  # xrandr: "--output NAME --mode WxH --rate R --pos X*Y --scale SxS"
  convertMonitorToXrandr = monitorStr:
    let
      parts = lib.splitString "," monitorStr;
      name = builtins.elemAt parts 0;
      resolution = builtins.elemAt parts 1;
      position = builtins.elemAt parts 2;
      scale = builtins.elemAt parts 3;

      # Parse resolution and refresh rate
      resolutionParts = if lib.hasInfix "@" resolution then
        lib.splitString "@" resolution
      else [ resolution "" ];
      res = builtins.elemAt resolutionParts 0;
      refresh = if (builtins.length resolutionParts) > 1
        then builtins.elemAt resolutionParts 1
        else "";

      # Build xrandr command parts
      outputArg = if name == "" then "--output auto" else "--output ${name}";
      modeArg = if res == "preferred" then "--auto" else "--mode ${res}";
      rateArg = if refresh != "" then "--rate ${refresh}" else "";
      posArg = if position == "auto" then "--auto" else "--pos ${lib.replaceStrings ["x"] ["*"] position}";
      scaleArg = if scale != "1" then "--scale ${scale}x${scale}" else "";
    in
    "${outputArg} ${modeArg} ${rateArg} ${posArg} ${scaleArg}";

  # Generate full xrandr command for all monitors
  xrandrCommand = "${pkgs.xorg.xrandr}/bin/xrandr " +
    (lib.concatStringsSep " " (map convertMonitorToXrandr config.windowManager.monitors));

in {
  options.i3 = { enable = mkEnableOption "Enable I3 window manager"; };

  config = mkIf config.i3.enable {

    services.network-manager-applet.enable = true;

    home.packages = with pkgs; [ feh brightnessctl i3lock-fancy-rapid ];

    # Configure keyboard layout and compose key for X11
    home.keyboard = {
      layout = "us";
      variant = "colemak";
      options = [ "caps:escape" "compose:${config.windowManager.composeKey}" ];
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
            command = "feh --bg-center ${config.theme.wallpaper}";
            always = false;
            notification = false;
          }
        ] ++ (builtins.map (app: {
          command = if app.workspace != null
            then "i3-msg 'workspace ${toString app.workspace}; exec ${app.command}'"
            else app.command;
          always = false;
          notification = false;
        }) (builtins.filter (app: app != null) (builtins.attrValues config.windowManager.autostartApps)));

        modifier = mod;

        fonts = with config.theme.font; {
          inherit style size;
          names = [ name ];
        };

        keybindings = lib.mkOptionDefault {
          "${mod}+Return" = "exec ${config.terminal.command}";
          "${mod}+x" =
            "exec sh -c '${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png'";
          "${mod}+o" = "exec ${config.launcher.show { mode = "run"; }}";
          "${mod}+Shift+x" =
            "exec sh -c '${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 15 8'";

          # Focus
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          # Move
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          # Multi monitors
          "${mod}+p" =
            "exec autorandr --change && feh --bg-center ${config.theme.wallpaper}";

          # Multimedia Keys

          ## Volume 
          XF86AudioRaiseVolume =
            "exec --no-startup-id pactl set-sink-volume 0 +5%";
          XF86AudioLowerVolume =
            "exec --no-startup-id pactl set-sink-volume 0 -5%";
          XF86AudioMute = "exec --no-startup-id pactl set-sink-mute 0 toggle";

          ## Backlighting
          XF86MonBrightnessUp = "exec brightnessctl set +10%";
          XF86MonBrightnessDown = "exec brightnessctl set 10%-";

        };

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

        colors = with config.theme.colors; {
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
          settings = { format = " cpu  %usage "; };
        };

        "cpu_temperature 1" = {
          position = 0.5;
          settings = { format = "%degrees °C"; };
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
          settings = { format = " %Y-%m-%d %H:%M:%S "; };
        };
      };
    };

    systemd.user.services.mpris-proxy = {
      Unit.Description = "Mpris proxy";
      Unit.After = [ "network.target" "sound.target" ];
      Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Install.WantedBy = [ "default.target" ];
    };
  };
}
