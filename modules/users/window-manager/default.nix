{ config, lib, pkgs, ... }:
with lib;

{
  imports = [
    ./hyprland
    ./i3
    ./sway
  ];

  options.windowManager = {
    enable = mkEnableOption "Enable window manager configuration";

    type = mkOption {
      description = "Window manager type";
      type = types.enum [ "hyprland" "i3" "sway" ];
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
  };

  config = mkIf config.windowManager.enable {
    # Automatically enable the selected window manager
    hyprland.enable = mkIf (config.windowManager.type == "hyprland") (mkDefault true);
    i3.enable = mkIf (config.windowManager.type == "i3") (mkDefault true);
    sway.enable = mkIf (config.windowManager.type == "sway") (mkDefault true);

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