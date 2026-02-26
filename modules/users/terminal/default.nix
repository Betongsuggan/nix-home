{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.terminal;

  # Build the terminal command based on backend
  terminalCommand =
    if cfg.backend == "alacritty" then "${pkgs.alacritty}/bin/alacritty"
    else if cfg.backend == "urxvt" then "${pkgs.rxvt-unicode}/bin/urxvt"
    else if cfg.backend == "ghostty" then "${pkgs.ghostty}/bin/ghostty"
    else throw "Unsupported terminal backend: ${cfg.backend}";

  # Build the terminal command with working directory
  terminalCommandWithCwd = { cwd }:
    if cfg.backend == "alacritty" then "${pkgs.alacritty}/bin/alacritty --working-directory \"${cwd}\""
    else if cfg.backend == "urxvt" then "${pkgs.rxvt-unicode}/bin/urxvt -cd \"${cwd}\""
    else if cfg.backend == "ghostty" then "${pkgs.ghostty}/bin/ghostty --working-directory=\"${cwd}\""
    else throw "Unsupported terminal backend: ${cfg.backend}";

in
{
  imports = [
    ./alacritty
    ./urxvt
    ./ghostty
  ];

  options.terminal = {
    enable = mkEnableOption "Enable terminal configuration";

    backend = mkOption {
      description = "Terminal emulator backend to use";
      type = types.enum [ "alacritty" "urxvt" "ghostty" ];
      default = "alacritty";
    };

    # Internal API for cross-module use
    command = mkOption {
      type = types.str;
      internal = true;
      readOnly = true;
      description = "Command to launch the default terminal";
    };

    commandWithCwd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to launch terminal in a specific directory.
        Usage: config.terminal.commandWithCwd { cwd = "/path/to/dir"; }
      '';
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
        default = cfg.backend == "alacritty";
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
        default = cfg.backend == "urxvt";
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

    ghostty = {
      enable = mkOption {
        description = "Enable Ghostty terminal";
        type = types.bool;
        default = cfg.backend == "ghostty";
      };

      extraSettings = mkOption {
        description = "Extra Ghostty settings";
        type = types.attrs;
        default = {};
      };
    };
  };

  config = mkIf cfg.enable {
    # Set the internal API options
    terminal.command = terminalCommand;
    terminal.commandWithCwd = terminalCommandWithCwd;
  };
}