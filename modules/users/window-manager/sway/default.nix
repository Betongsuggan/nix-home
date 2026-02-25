{ config, lib, pkgs, ... }:
with lib;

let
  inherit (pkgs) pamixer playerctl;
  modifier = "Mod4";

  # Convert Hyprland monitor format to Sway output format
  # Hyprland: "name,resolution@refresh,position,scale"
  # Sway: "output name resolution WxH@RHz position X Y scale S"
  convertMonitorToSwayOutput = monitorStr:
    let
      parts = lib.splitString "," monitorStr;
      name = if (builtins.elemAt parts 0) == "" then "*" else (builtins.elemAt parts 0);
      resolution = builtins.elemAt parts 1;
      position = builtins.elemAt parts 2;
      scale = builtins.elemAt parts 3;

      # Format resolution (add Hz if it contains @)
      resolutionFormatted =
        if resolution == "preferred" then "preferred"
        else if lib.hasInfix "@" resolution then
          let
            resParts = lib.splitString "@" resolution;
            res = builtins.elemAt resParts 0;
            refresh = builtins.elemAt resParts 1;
          in "${res}@${refresh}Hz"
        else resolution;

      # Format position (convert "0x0" to "0 0" or keep "auto")
      positionFormatted =
        if position == "auto" then "auto"
        else lib.replaceStrings ["x"] [" "] position;
    in
    "output ${name} resolution ${resolutionFormatted} position ${positionFormatted} scale ${scale}";

  # Generate output configurations for all monitors
  monitorOutputs = lib.concatStringsSep "\n"
    (map convertMonitorToSwayOutput config.windowManager.monitors);

in {
  options.sway = { enable = mkEnableOption "Enable Sway"; };

  config = mkIf config.sway.enable {

    home.packages = with pkgs; [
      swaylock-fancy
      swayidle
      sway-contrib.grimshot
      wl-clipboard
      #mako
      networkmanager_dmenu
    ];

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      config = rec {
        inherit modifier;
        terminal = config.terminal.command;
        menu = config.launcher.show { mode = "drun"; };

        fonts = with config.theme.font; {
          inherit style size;
          names = [ name ];
        };

        startup = [{
          command = "blueman-applet";
          always = false;
        }] ++ (builtins.map (app: {
          command = if app.workspace != null
            then "swaymsg 'workspace ${toString app.workspace}; exec ${app.command}'"
            else app.command;
          always = false;
        }) (builtins.filter (app: app != null) (builtins.attrValues config.windowManager.autostartApps)));

        gaps = {
          top = 6;
          horizontal = 6;
          vertical = 6;
          outer = 6;
          inner = 6;
          left = 6;
          right = 6;
        };

        bars = [{
          position = "bottom";
          command = "waybar";
        }];

        keybindings = lib.mkOptionDefault {
          "${modifier}+o" = "exec ${config.launcher.show { mode = "drun"; }}";

          "${modifier}+Shift+x" =
            "exec ${pkgs.swaylock-fancy}/bin/swaylock-fancy";

          "${modifier}+Shift+p" =
            "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot save area ~/Pictures/$(date -Iseconds)";
        };

        input = { "*" = { tap = "enabled"; }; };

        colors = with config.theme.colors; {
          background = "${background}";

          focused = {
            border = "${thirdText}";
            background = "${thirdText}";
            text = "${borderDark}";
            indicator = "${purple}";
            childBorder = "${borderDark}";
          };

          unfocused = {
            border = "${borderDark}";
            background = "${borderDark}";
            text = "${utilityText}";
            indicator = "${purple}";
            childBorder = "${borderDark}";
          };

          focusedInactive = {
            border = "${borderDark}";
            background = "${borderDark}";
            text = "${borderDark}";
            indicator = "${purple}";
            childBorder = "${borderDark}";
          };

          urgent = {
            border = "${alertText}";
            background = "${alertText}";
            text = "${mainText}";
            indicator = "${mainText}";
            childBorder = "${mainText}";
          };
        };

        window.titlebar = false;
      };
      extraConfig = ''
        # Monitor configuration
        ${monitorOutputs}

        input * xkb_layout "us,us"
        input * xkb_variant "colemak,"
        input * xkb_options "caps:escape,compose:${config.windowManager.composeKey},grp:shifts_toggle"

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
