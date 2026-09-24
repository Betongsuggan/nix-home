{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  imports = [
    ./hyprland
    ./i3
    ./niri
    ./sway
  ];

  options.my.window-manager = {
    enable = mkEnableOption "Enable window manager configuration";

    backend = mkOption {
      description = "Window manager backend to use";
      type = types.enum [
        "hyprland"
        "i3"
        "niri"
        "sway"
      ];
      default = "hyprland";
    };

    autostartApps = mkOption {
      description = "Applications to autostart, with optional workspace assignment";
      type = types.attrsOf (
        types.nullOr (
          types.submodule {
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
          }
        )
      );
      default = { };
    };

    monitors = mkOption {
      description = ''
        Outputs by connector name (e.g. "DP-2", or a virtual monitor such as
        "SUNSHINE"). Outputs not listed use their preferred mode, automatic
        position and scale 1. Each backend renders this in its own format.
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to use this output at all.";
            };
            mode = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    width = mkOption { type = types.int; };
                    height = mkOption { type = types.int; };
                    refresh = mkOption {
                      type = types.nullOr types.number;
                      default = null;
                      description = "Refresh rate in Hz (null: the mode's default).";
                    };
                  };
                }
              );
              default = null;
              description = "Resolution and refresh rate; null uses the preferred mode.";
            };
            position = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    x = mkOption { type = types.int; };
                    y = mkOption { type = types.int; };
                  };
                }
              );
              default = null;
              description = "Position in the global layout; null places it automatically.";
            };
            scale = mkOption {
              type = types.number;
              default = 1;
            };
            vrr = mkOption {
              type = types.bool;
              default = false;
              description = "Variable refresh rate.";
            };
            hdr = mkOption {
              type = types.bool;
              default = false;
              description = "HDR color management (Hyprland).";
            };
            bitdepth = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Output bit depth, e.g. 10 (Hyprland).";
            };
            sdrBrightness = mkOption {
              type = types.nullOr types.number;
              default = null;
              description = "SDR content brightness in HDR mode (Hyprland).";
            };
            sdrSaturation = mkOption {
              type = types.nullOr types.number;
              default = null;
              description = "SDR content saturation in HDR mode (Hyprland).";
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          DP-2 = {
            mode = { width = 3440; height = 1440; refresh = 240; };
            hdr = true;
            bitdepth = 10;
          };
          HDMI-A-1.enable = false;
        }
      '';
    };

    virtualMonitors = mkOption {
      description = ''
        Virtual/headless monitor names to create at window manager startup.
        Useful for streaming (e.g., Sunshine) without a physical display connected.

        Configure its mode in the regular `monitors` option, e.g.:
          monitors.SUNSHINE.mode = { width = 1920; height = 1080; refresh = 60; };
          virtualMonitors = [ "SUNSHINE" ];
      '';
      type = types.listOf types.str;
      default = [ ];
      example = [ "SUNSHINE" ];
    };

    workspaceBindings = mkOption {
      description = "Bind workspaces to specific monitors";
      type = types.listOf (
        types.submodule {
          options = {
            workspace = mkOption {
              type = types.int;
              description = "Workspace number";
              example = 10;
            };
            monitor = mkOption {
              type = types.str;
              description = "Monitor name (e.g., DP-1, SUNSHINE)";
              example = "DP-1";
            };
            default = mkOption {
              type = types.bool;
              default = false;
              description = "Make this the default workspace for the monitor";
            };
          };
        }
      );
      default = [ ];
      example = [
        {
          workspace = 10;
          monitor = "SUNSHINE";
          default = true;
        }
      ];
    };

    composeKey = mkOption {
      type = types.str;
      default = "ralt";
      description = ''
        Keyboard key to use as the compose key for typing special characters.

        Available options:
        - ralt: Right Alt key (default)
        - lalt: Left Alt key
        - rwin: Right Windows/Super key
        - lwin: Left Windows/Super key
        - menu: Menu key
        - rctrl: Right Control key
        - lctrl: Left Control key
        - caps: Caps Lock key
        - prsc: Print Screen key
        - sclk: Scroll Lock key

        Common choices are 'ralt' (Right Alt) or 'menu' (Menu key).

        The compose key allows you to type special characters by pressing
        the compose key followed by a sequence of keys. For example, with
        Swedish character mappings, Compose+o+o produces ö.
      '';
      example = "menu";
    };

    touchOutput = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Output name to map touchscreen input to. Set to null to disable
        touchscreen output mapping (uses default behavior).
        Common values: "eDP-1" for laptop displays.
      '';
      example = "eDP-1";
    };
  };

  config = mkIf config.my.window-manager.enable {
    # Every backend's binds use these; each reads the backend itself
    my.launcher.enable = mkDefault true;
    my.controls.enable = mkDefault true;
    my.notifications.enable = mkDefault true;

    # Automatically enable the selected window manager
    my.window-manager.hyprland.enable = mkIf (config.my.window-manager.backend == "hyprland") (
      mkDefault true
    );
    my.window-manager.i3.enable = mkIf (config.my.window-manager.backend == "i3") (mkDefault true);
    my.window-manager.niri.enable = mkIf (config.my.window-manager.backend == "niri") (mkDefault true);
    my.window-manager.sway.enable = mkIf (config.my.window-manager.backend == "sway") (mkDefault true);

    # Custom compose sequences for special characters (works across all window managers)
    home.file.".XCompose".text = ''
      include "%L"

      # Swedish characters using Multi_key (Compose key)
      <Multi_key> <o> <o> : "ö"
      <Multi_key> <O> <O> : "Ö"
      <Multi_key> <e> <e> : "ä"
      <Multi_key> <E> <E> : "Ä"
      <Multi_key> <a> <a> : "å"
      <Multi_key> <A> <A> : "Å"
    '';

    # Environment variables for XIM to make .XCompose work in XWayland apps
    home.sessionVariables = {
      GTK_IM_MODULE = "xim"; # GTK apps (e.g., Slack) read .XCompose
      QT_IM_MODULE = "xim"; # Qt apps read .XCompose
      XMODIFIERS = "@im=none"; # Disable other input method frameworks
    };
  };
}
