{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.file-manager;

  # How each backend opens a directory and reveals a file
  backends = {
    thunar = {
      open = path: "${pkgs.xfce.thunar}/bin/thunar \"${path}\"";
      select = file: "${pkgs.xfce.thunar}/bin/thunar \"${file}\"";
    };
    nautilus = {
      open = path: "${pkgs.nautilus}/bin/nautilus \"${path}\"";
      select = file: "${pkgs.nautilus}/bin/nautilus --select \"${file}\"";
    };
    dolphin = {
      open = path: "${pkgs.kdePackages.dolphin}/bin/dolphin \"${path}\"";
      select = file: "${pkgs.kdePackages.dolphin}/bin/dolphin --select \"${file}\"";
    };
    pcmanfm = {
      open = path: "${pkgs.pcmanfm}/bin/pcmanfm \"${path}\"";
      select = file: "${pkgs.pcmanfm}/bin/pcmanfm \"${file}\"";
    };
  };
  fileManagerOpenCmd = { path }: backends.${cfg.backend}.open path;
  fileManagerSelectCmd = { file }: backends.${cfg.backend}.select file;

  # Get the terminal command - use override or fall back to terminal module
  terminalCmd =
    if cfg.terminalOverride != null then cfg.terminalOverride else config.my.terminal.commandWithCwd;

in
{
  imports = [
    ./thunar
  ];

  options.my.file-manager = {
    enable = mkEnableOption "file manager";

    backend = mkOption {
      type = types.enum (attrNames backends);
      default = "thunar";
      description = "File manager backend to use";
    };

    networkShares.enable = mkEnableOption "browsing SMB/Samba network shares" // {
      description = ''
        Enable browsing SMB/Samba shares on the local network.
        Auto-enables Avahi (mDNS) on the system so shares show up under
        "Network" in the file manager and `.local` hostnames resolve.
      '';
    };

    bookmarks = mkOption {
      type = types.listOf types.str;
      default = [ ];
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
        If null, uses config.my.terminal.commandWithCwd from the terminal module.
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
        Usage: config.my.file-manager.open { path = "/path/to/dir"; }
      '';
    };

    select = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to open file manager and select a specific file.
        Usage: config.my.file-manager.select { file = "/path/to/file"; }
      '';
    };

    terminal = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Terminal command with working directory for file manager actions.
        This uses terminalOverride if set, otherwise falls back to config.my.terminal.commandWithCwd.
        Usage: config.my.file-manager.terminal { cwd = "/path/to/dir"; }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Set the internal API options
    my.file-manager.open = fileManagerOpenCmd;
    my.file-manager.select = fileManagerSelectCmd;
    my.file-manager.terminal = terminalCmd;

    # Automatically enable the selected file manager backend
    my.file-manager.thunar.enable = mkIf (cfg.backend == "thunar") (mkDefault true);

    # Generate GTK bookmarks file if bookmarks are specified
    home.file.".config/gtk-3.0/bookmarks" = mkIf (cfg.bookmarks != [ ]) {
      text = concatStringsSep "\n" cfg.bookmarks + "\n";
    };
  };
}
