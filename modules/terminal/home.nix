{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.terminal;

  # How to launch each backend, plain and in a given working directory
  backends = {
    alacritty = {
      command = "${pkgs.alacritty}/bin/alacritty";
      withCwd = cwd: "${pkgs.alacritty}/bin/alacritty --working-directory \"${cwd}\"";
    };
    urxvt = {
      command = "${pkgs.rxvt-unicode}/bin/urxvt";
      withCwd = cwd: "${pkgs.rxvt-unicode}/bin/urxvt -cd \"${cwd}\"";
    };
    ghostty = {
      command = "${pkgs.ghostty}/bin/ghostty";
      withCwd = cwd: "${pkgs.ghostty}/bin/ghostty --working-directory=\"${cwd}\"";
    };
  };
  selected = backends.${cfg.backend};
  terminalCommand = selected.command;
  terminalCommandWithCwd = { cwd }: selected.withCwd cwd;

in
{
  imports = [
    ./alacritty
    ./urxvt
    ./ghostty
  ];

  options.my.terminal = {
    enable = mkEnableOption "Enable terminal configuration";

    backend = mkOption {
      description = "Terminal emulator backend to use";
      type = types.enum (attrNames backends);
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
        Usage: config.my.terminal.commandWithCwd { cwd = "/path/to/dir"; }
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
        default = cfg.enable && cfg.backend == "alacritty";
      };

      extraSettings = mkOption {
        description = "Extra Alacritty settings";
        type = types.attrs;
        default = { };
      };
    };

    urxvt = {
      enable = mkOption {
        description = "Enable urxvt terminal";
        type = types.bool;
        default = cfg.enable && cfg.backend == "urxvt";
      };

      extraConfig = mkOption {
        description = "Extra urxvt configuration";
        type = types.attrs;
        default = { };
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
        default = cfg.enable && cfg.backend == "ghostty";
      };

      extraSettings = mkOption {
        description = "Extra Ghostty settings";
        type = types.attrs;
        default = { };
      };

      keybindings = mkOption {
        description = "Ghostty keybindings (list of 'key=action' strings)";
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {
    # Set the internal API options
    my.terminal.command = terminalCommand;
    my.terminal.commandWithCwd = terminalCommandWithCwd;
  };
}
