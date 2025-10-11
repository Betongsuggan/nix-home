{ config, lib, pkgs, ... }:
with lib;

{
  imports = [
    ./alacritty
    ./urxvt
  ];

  options.terminal = {
    enable = mkEnableOption "Enable terminal configuration";

    defaultTerminal = mkOption {
      description = "Default terminal emulator to use";
      type = types.enum [ "alacritty" "urxvt" ];
      default = "alacritty";
    };

    font = {
      family = mkOption {
        description = "Terminal font family (inherits from theme if not specified)";
        type = types.nullOr types.str;
        default = null;
      };

      size = mkOption {
        description = "Terminal font size";
        type = types.int;
        default = 12;
      };
    };

    colors = {
      useTheme = mkOption {
        description = "Use theme colors for terminal";
        type = types.bool;
        default = true;
      };
    };

    opacity = mkOption {
      description = "Terminal background opacity (0.0 - 1.0)";
      type = types.float;
      default = 1.0;
    };

    alacritty = {
      enable = mkOption {
        description = "Enable Alacritty terminal";
        type = types.bool;
        default = config.terminal.defaultTerminal == "alacritty";
      };

      extraSettings = mkOption {
        description = "Extra Alacritty settings";
        type = types.attrs;
        default = {};
      };
    };

    urxvt = {
      enable = mkOption {
        description = "Enable urxvt terminal";
        type = types.bool;
        default = config.terminal.defaultTerminal == "urxvt";
      };

      extraConfig = mkOption {
        description = "Extra urxvt configuration";
        type = types.attrs;
        default = {};
      };

      keybindings = mkOption {
        description = "urxvt keybindings";
        type = types.attrsOf types.str;
        default = {
          "Shift-Control-V" = "eval:paste_clipboard";
          "Shift-Control-C" = "eval:selection_to_clipboard";
        };
      };
    };
  };

  config = mkIf config.terminal.enable {
    # The individual terminal modules are enabled based on terminal.{alacritty,urxvt}.enable options
    # which are automatically set based on the defaultTerminal selection
  };
}