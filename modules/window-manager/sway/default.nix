{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  modifier = "Mod4";

  wmLib = import ../lib.nix { inherit lib; };

  # my.window-manager.monitors as sway `output` lines (unlisted outputs keep
  # sway's defaults)
  swayOutput =
    m:
    if !m.enable then
      "output ${m.name} disable"
    else
      concatStringsSep " " (
        [ "output ${m.name}" ]
        ++ optional (m.mode != null) (
          "resolution ${toString m.mode.width}x${toString m.mode.height}"
          + optionalString (m.mode.refresh != null) "@${wmLib.fmtNum m.mode.refresh}Hz"
        )
        ++ optional (m.position != null) "position ${toString m.position.x} ${toString m.position.y}"
        ++ [ "scale ${wmLib.fmtNum m.scale}" ]
        ++ optional m.vrr "adaptive_sync on"
      );
  monitorOutputs = concatMapStringsSep "\n" swayOutput (
    wmLib.outputList config.my.window-manager.monitors
  );

in
{
  options.my.window-manager.sway = {
    enable = mkEnableOption "Enable Sway";
    lockscreen.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable lockscreen functionality (swaylock, idle lock, etc.)";
    };
  };

  config = mkIf config.my.window-manager.sway.enable {

    home.packages =
      with pkgs;
      [
        swayidle
        sway-contrib.grimshot
        wl-clipboard
        #mako
        networkmanager_dmenu
      ]
      ++ optionals config.my.window-manager.sway.lockscreen.enable [
        swaylock-effects
      ];

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      config = rec {
        inherit modifier;
        terminal = config.my.terminal.command;
        menu = config.my.launcher.show { mode = "drun"; };

        fonts = with config.my.theming.font; {
          inherit style size;
          names = [ name ];
        };

        startup = [
          {
            command = "blueman-applet";
            always = false;
          }
        ]
        ++ (builtins.map
          (app: {
            command =
              if app.workspace != null then
                "swaymsg 'workspace ${toString app.workspace}; exec ${app.command}'"
              else
                app.command;
            always = false;
          })
          (builtins.filter (app: app != null) (builtins.attrValues config.my.window-manager.autostartApps))
        );

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

        # The shared keymap (my.window-manager.keybinds) on top of sway's defaults
        keybindings = lib.mkOptionDefault (
          wmLib.i3Keybindings "sway" modifier config.my.window-manager.keybinds
        );

        input = {
          "*" = {
            tap = "enabled";
          };
        };

        colors = with config.my.theming.colors; {
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
        input * xkb_options "caps:escape,compose:${config.my.window-manager.composeKey},grp:shifts_toggle"

      '';
    };

    # Swaylock configuration (styled to match hyprlock)
    programs.swaylock = mkIf config.my.window-manager.sway.lockscreen.enable {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        # Background with blur (like hyprlock blur_passes=2, blur_size=4)
        image = "${config.my.theming.wallpaper}";
        scaling = "fill";
        effect-blur = "7x5";
        effect-vignette = "0.5:0.5";

        # Clock display (like hyprlock's time label)
        clock = true;
        timestr = "%H:%M";
        datestr = "";

        # Indicator styling
        indicator = true;
        indicator-radius = 100;
        indicator-thickness = 7;

        # Colors matching theme
        color = lib.strings.removePrefix "#" config.my.theming.colors.primary.background;
        inside-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.background;
        inside-clear-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.background;
        inside-ver-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.background;
        inside-wrong-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.background;
        key-hl-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        ring-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        ring-clear-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        ring-ver-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        ring-wrong-color = lib.strings.removePrefix "#" config.my.theming.colors.normal.red;
        line-color = "00000000";
        text-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        text-clear-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        text-ver-color = lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground;
        text-wrong-color = lib.strings.removePrefix "#" config.my.theming.colors.normal.red;

        # Font settings
        font = config.my.theming.font.name;
        font-size = 24;

        # Behavior (matching hyprlock's no_fade_in/out)
        fade-in = 0;
        grace = 0;
        show-failed-attempts = true;
      };
    };
  };
}
