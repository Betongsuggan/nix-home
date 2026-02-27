{ config, lib, pkgs, ... }:
with lib;

{
  imports = [
    ./hyprland
    ./i3
    ./niri
    ./sway
  ];

  options.windowManager = {
    enable = mkEnableOption "Enable window manager configuration";

    backend = mkOption {
      description = "Window manager backend to use";
      type = types.enum [ "hyprland" "i3" "niri" "sway" ];
      default = "hyprland";
    };

    autostartApps = mkOption {
      description = "Applications to autostart, with optional workspace assignment";
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
      default = {};
    };

    monitors = mkOption {
      description = ''
        Monitor configuration strings (Hyprland format).
        Format: "name,resolution@refresh,position,scale"
        Examples:
          - ",preferred,auto,1" - Use preferred resolution, auto position, scale 1
          - "DP-1,3440x1440@100,0x0,1" - Specific monitor with custom settings
          - "HDMI-A-1,3840x2160@120,auto,2" - 4K monitor with 2x scaling
      '';
      type = types.listOf types.str;
      default = [ ",preferred,auto,1" ];
      example = [
        "DP-1,3440x1440@100,auto,1"
        "HDMI-A-1,3840x2160@120,auto,2"
      ];
    };

    virtualMonitors = mkOption {
      description = ''
        Virtual/headless monitor names to create at window manager startup.
        Useful for streaming (e.g., Sunshine) without a physical display connected.

        Configure resolution in the regular 'monitors' option, e.g.:
          monitors = [ "SUNSHINE,1920x1080@60,auto,1" ];
          virtualMonitors = [ "SUNSHINE" ];
      '';
      type = types.listOf types.str;
      default = [ ];
      example = [ "SUNSHINE" ];
    };

    workspaceBindings = mkOption {
      description = "Bind workspaces to specific monitors";
      type = types.listOf (types.submodule {
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
      });
      default = [ ];
      example = [{
        workspace = 10;
        monitor = "SUNSHINE";
        default = true;
      }];
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

  config = mkIf config.windowManager.enable {
    # Automatically enable the selected window manager
    hyprland.enable = mkIf (config.windowManager.backend == "hyprland") (mkDefault true);
    i3.enable = mkIf (config.windowManager.backend == "i3") (mkDefault true);
    niri.enable = mkIf (config.windowManager.backend == "niri") (mkDefault true);
    sway.enable = mkIf (config.windowManager.backend == "sway") (mkDefault true);

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
  };
}