{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fileManager;

  # Build the file manager open command based on backend
  fileManagerOpenCmd = { path }:
    if cfg.backend == "thunar" then "${pkgs.xfce.thunar}/bin/thunar \"${path}\""
    else if cfg.backend == "nautilus" then "${pkgs.gnome.nautilus}/bin/nautilus \"${path}\""
    else if cfg.backend == "dolphin" then "${pkgs.kdePackages.dolphin}/bin/dolphin \"${path}\""
    else if cfg.backend == "pcmanfm" then "${pkgs.pcmanfm}/bin/pcmanfm \"${path}\""
    else throw "Unsupported file manager backend: ${cfg.backend}";

  # Build the file manager select command based on backend
  fileManagerSelectCmd = { file }:
    if cfg.backend == "thunar" then "${pkgs.xfce.thunar}/bin/thunar \"${file}\""
    else if cfg.backend == "nautilus" then "${pkgs.gnome.nautilus}/bin/nautilus --select \"${file}\""
    else if cfg.backend == "dolphin" then "${pkgs.kdePackages.dolphin}/bin/dolphin --select \"${file}\""
    else if cfg.backend == "pcmanfm" then "${pkgs.pcmanfm}/bin/pcmanfm \"${file}\""
    else throw "Unsupported file manager backend: ${cfg.backend}";

  # Get the terminal command - use override or fall back to terminal module
  terminalCmd =
    if cfg.terminalOverride != null
    then cfg.terminalOverride
    else config.terminal.commandWithCwd;

in
{
  imports = [
    ./thunar
  ];

  options.fileManager = {
    enable = mkEnableOption "file manager";

    backend = mkOption {
      type = types.enum [ "thunar" "nautilus" "dolphin" "pcmanfm" ];
      default = "thunar";
      description = "File manager backend to use";
    };

    bookmarks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of bookmark paths for the file manager sidebar.
        Format: "file:///path/to/directory" or "file:///path/to/directory Label"
      '';
      example = [
        "file:///home/user/Documents"
        "file:///home/user/Downloads"
        "file:///home/user/Development Projects"
      ];
    };

    terminalOverride = mkOption {
      type = types.nullOr (types.functionTo types.str);
      default = null;
      description = ''
        Optional override for terminal command with working directory.
        If null, uses config.terminal.commandWithCwd from the terminal module.
        Usage: { cwd }: "terminal-command --dir \${cwd}"
      '';
    };

    # Internal API for cross-module use
    open = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to open a path in the file manager.
        Usage: config.fileManager.open { path = "/path/to/dir"; }
      '';
    };

    select = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to open file manager and select a specific file.
        Usage: config.fileManager.select { file = "/path/to/file"; }
      '';
    };

    terminal = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Terminal command with working directory for file manager actions.
        This uses terminalOverride if set, otherwise falls back to config.terminal.commandWithCwd.
        Usage: config.fileManager.terminal { cwd = "/path/to/dir"; }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Set the internal API options
    fileManager.open = fileManagerOpenCmd;
    fileManager.select = fileManagerSelectCmd;
    fileManager.terminal = terminalCmd;

    # Automatically enable the selected file manager backend
    fileManager.thunar.enable = mkIf (cfg.backend == "thunar") (mkDefault true);

    # Generate GTK bookmarks file if bookmarks are specified
    home.file.".config/gtk-3.0/bookmarks" = mkIf (cfg.bookmarks != []) {
      text = concatStringsSep "\n" cfg.bookmarks + "\n";
    };
  };
}
