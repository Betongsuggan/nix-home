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
  };

  config = mkIf config.windowManager.enable {
    # Automatically enable the selected window manager
    hyprland.enable = mkIf (config.windowManager.type == "hyprland") (mkDefault true);
    i3.enable = mkIf (config.windowManager.type == "i3") (mkDefault true);
    sway.enable = mkIf (config.windowManager.type == "sway") (mkDefault true);
  };
}