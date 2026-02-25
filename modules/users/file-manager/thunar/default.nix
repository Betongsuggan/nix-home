{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fileManager;
  thunarCfg = cfg.thunar;

  # Build custom actions XML
  customActionsXml = let
    # Default actions
    openTerminalAction = optionalString thunarCfg.defaultActions.openTerminal ''
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <unique-id>open-terminal-here</unique-id>
        <command>${cfg.terminal { cwd = "%f"; }}</command>
        <description>Open terminal in this directory</description>
        <patterns>*</patterns>
        <directories/>
      </action>
    '';

    copyPathAction = optionalString thunarCfg.defaultActions.copyPath ''
      <action>
        <icon>edit-copy</icon>
        <name>Copy Path</name>
        <unique-id>copy-path</unique-id>
        <command>echo -n %f | ${pkgs.wl-clipboard}/bin/wl-copy</command>
        <description>Copy file path to clipboard</description>
        <patterns>*</patterns>
        <directories/>
        <audio-files/>
        <image-files/>
        <other-files/>
        <text-files/>
        <video-files/>
      </action>
    '';

    computeChecksumAction = optionalString thunarCfg.defaultActions.computeChecksum ''
      <action>
        <icon>dialog-information</icon>
        <name>Compute SHA256</name>
        <unique-id>compute-checksum</unique-id>
        <command>${pkgs.coreutils}/bin/sha256sum %f | ${pkgs.wl-clipboard}/bin/wl-copy</command>
        <description>Compute SHA256 checksum and copy to clipboard</description>
        <patterns>*</patterns>
        <other-files/>
        <text-files/>
        <audio-files/>
        <image-files/>
        <video-files/>
      </action>
    '';

    openAsRootAction = optionalString thunarCfg.defaultActions.openAsRoot ''
      <action>
        <icon>dialog-password</icon>
        <name>Open as Root</name>
        <unique-id>open-as-root</unique-id>
        <command>pkexec ${pkgs.xfce.thunar}/bin/thunar %f</command>
        <description>Open folder as root</description>
        <patterns>*</patterns>
        <directories/>
      </action>
    '';

    setAsWallpaperAction = optionalString thunarCfg.defaultActions.setAsWallpaper ''
      <action>
        <icon>preferences-desktop-wallpaper</icon>
        <name>Set as Wallpaper</name>
        <unique-id>set-as-wallpaper</unique-id>
        <command>${pkgs.feh}/bin/feh --bg-fill %f</command>
        <description>Set image as desktop wallpaper</description>
        <patterns>*.jpg;*.jpeg;*.png;*.bmp;*.gif</patterns>
        <image-files/>
      </action>
    '';

    # User custom actions
    userCustomActions = concatMapStringsSep "\n" (action: ''
      <action>
        <icon>${action.icon or "application-x-executable"}</icon>
        <name>${action.name}</name>
        <unique-id>${action.id}</unique-id>
        <command>${action.command}</command>
        <description>${action.description or ""}</description>
        <patterns>${action.patterns or "*"}</patterns>
        ${optionalString (action.directories or false) "<directories/>"}
        ${optionalString (action.audioFiles or false) "<audio-files/>"}
        ${optionalString (action.imageFiles or false) "<image-files/>"}
        ${optionalString (action.otherFiles or false) "<other-files/>"}
        ${optionalString (action.textFiles or false) "<text-files/>"}
        ${optionalString (action.videoFiles or false) "<video-files/>"}
      </action>
    '') thunarCfg.customActions;

  in ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    ${openTerminalAction}
    ${copyPathAction}
    ${computeChecksumAction}
    ${openAsRootAction}
    ${setAsWallpaperAction}
    ${userCustomActions}
    </actions>
  '';

  # Build tumbler configuration
  tumblerConfig = ''
    # Tumbler Configuration

    [Tumbler]
    MaxFileSize=${toString (thunarCfg.thumbnails.maxFileSize * 1024 * 1024)}

    [FFMpegThumbnailer]
    Disabled=${if thunarCfg.thumbnails.enableVideo then "false" else "true"}

    [PopplerThumbnailer]
    Disabled=${if thunarCfg.thumbnails.enablePdf then "false" else "true"}

    [RawThumbnailer]
    Disabled=${if thunarCfg.thumbnails.enableRaw then "false" else "true"}
  '';

  # Archive manager package
  archiveManagerPkg =
    if thunarCfg.archive.manager == "file-roller" then pkgs.file-roller
    else if thunarCfg.archive.manager == "xarchiver" then pkgs.xarchiver
    else if thunarCfg.archive.manager == "engrampa" then pkgs.mate.engrampa
    else throw "Unsupported archive manager: ${thunarCfg.archive.manager}";

in
{
  options.fileManager.thunar = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Thunar file manager";
    };

    thumbnails = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable thumbnail generation";
      };

      maxFileSize = mkOption {
        type = types.int;
        default = 100;
        description = "Maximum file size in MB for thumbnail generation";
      };

      enableVideo = mkOption {
        type = types.bool;
        default = true;
        description = "Enable video thumbnails (requires ffmpegthumbnailer)";
      };

      enablePdf = mkOption {
        type = types.bool;
        default = true;
        description = "Enable PDF thumbnails (requires poppler-utils)";
      };

      enableRaw = mkOption {
        type = types.bool;
        default = false;
        description = "Enable RAW image thumbnails";
      };
    };

    archive = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable archive plugin and manager";
      };

      manager = mkOption {
        type = types.enum [ "file-roller" "xarchiver" "engrampa" ];
        default = "file-roller";
        description = "Archive manager to use with Thunar";
      };
    };

    volumeManager = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable volume manager (thunar-volman)";
      };

      autoMount = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically mount removable media";
      };

      autoRun = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically run programs on removable media";
      };
    };

    defaultActions = {
      openTerminal = mkOption {
        type = types.bool;
        default = true;
        description = "Add 'Open Terminal Here' action to context menu";
      };

      copyPath = mkOption {
        type = types.bool;
        default = true;
        description = "Add 'Copy Path' action to context menu";
      };

      computeChecksum = mkOption {
        type = types.bool;
        default = false;
        description = "Add 'Compute SHA256' action to context menu";
      };

      openAsRoot = mkOption {
        type = types.bool;
        default = false;
        description = "Add 'Open as Root' action to context menu";
      };

      setAsWallpaper = mkOption {
        type = types.bool;
        default = false;
        description = "Add 'Set as Wallpaper' action for images";
      };
    };

    customActions = mkOption {
      type = types.listOf (types.submodule {
        options = {
          id = mkOption {
            type = types.str;
            description = "Unique identifier for the action";
          };
          name = mkOption {
            type = types.str;
            description = "Display name for the action";
          };
          command = mkOption {
            type = types.str;
            description = "Command to execute (%f = file, %d = directory, %n = filename)";
          };
          icon = mkOption {
            type = types.str;
            default = "application-x-executable";
            description = "Icon name for the action";
          };
          description = mkOption {
            type = types.str;
            default = "";
            description = "Description of the action";
          };
          patterns = mkOption {
            type = types.str;
            default = "*";
            description = "File patterns to match (semicolon-separated)";
          };
          directories = mkOption {
            type = types.bool;
            default = false;
            description = "Apply to directories";
          };
          audioFiles = mkOption {
            type = types.bool;
            default = false;
            description = "Apply to audio files";
          };
          imageFiles = mkOption {
            type = types.bool;
            default = false;
            description = "Apply to image files";
          };
          textFiles = mkOption {
            type = types.bool;
            default = false;
            description = "Apply to text files";
          };
          videoFiles = mkOption {
            type = types.bool;
            default = false;
            description = "Apply to video files";
          };
          otherFiles = mkOption {
            type = types.bool;
            default = false;
            description = "Apply to other files";
          };
        };
      });
      default = [];
      description = "Custom context menu actions";
    };

    view = {
      defaultView = mkOption {
        type = types.enum [ "icon" "compact" "detailed" ];
        default = "detailed";
        description = "Default view mode";
      };

      showHidden = mkOption {
        type = types.bool;
        default = false;
        description = "Show hidden files by default";
      };

      sortColumn = mkOption {
        type = types.enum [ "name" "size" "type" "date" ];
        default = "name";
        description = "Default sort column";
      };

      sortOrder = mkOption {
        type = types.enum [ "ascending" "descending" ];
        default = "ascending";
        description = "Default sort order";
      };
    };
  };

  config = mkIf thunarCfg.enable {
    # Core Thunar, plugins (archive, volman), xfconf, gvfs, tumbler, and udisks2
    # are provided by the system module (fileManagerSystem.enable = true)
    home.packages = with pkgs; []
      # Thumbnail support (beyond what system tumbler provides)
      ++ optional thunarCfg.thumbnails.enableVideo ffmpegthumbnailer
      ++ optional thunarCfg.thumbnails.enablePdf poppler-utils

      # Archive manager (user choice)
      ++ optional thunarCfg.archive.enable archiveManagerPkg;

    # Custom actions configuration
    home.file.".config/Thunar/uca.xml" = {
      text = customActionsXml;
      force = true;
    };

    # Tumbler configuration
    home.file.".config/tumbler/tumbler.rc" = mkIf thunarCfg.thumbnails.enable {
      text = tumblerConfig;
    };

    # Volume manager xfconf settings (generates thunar-volman.xml)
    xfconf.settings = mkIf thunarCfg.volumeManager.enable {
      thunar-volman = {
        "automount-drives/enabled" = thunarCfg.volumeManager.autoMount;
        "automount-media/enabled" = thunarCfg.volumeManager.autoMount;
        "autobrowse/enabled" = thunarCfg.volumeManager.autoMount;
        "autoopen/enabled" = false;  # Don't auto-open file manager on mount
        "autorun/enabled" = thunarCfg.volumeManager.autoRun;
      };
    };
  };
}
