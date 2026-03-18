{ config, lib, ... }:
with lib;

let
  cfg = config.emulation-server.user;

  dataDir = cfg.dataDir;
in {
  options.emulation-server.user = {
    enable = mkEnableOption "Emulation server user configuration (directory structure)";

    dataDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/emulation";
      description = "Root directory for emulation data";
    };

    systems = mkOption {
      type = types.listOf types.str;
      default = [
        "snes"
        "nes"
        "gb"
        "gbc"
        "gba"
        "n64"
        "nds"
        "psx"
        "ps2"
        "psp"
        "megadrive"
        "mastersystem"
        "gamecube"
        "wii"
        "dreamcast"
        "saturn"
        "arcade"
      ];
      description = "Emulation systems to create ROM subdirectories for";
    };

    standaloneEmulators = mkOption {
      type = types.listOf types.str;
      default = [ "retroarch" "ppsspp" "duckstation" "dolphin" ];
      description = "Standalone emulators to create save subdirectories for";
    };
  };

  config = mkIf cfg.enable {
    home.activation.createEmulationDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # ROM directories
      ${concatMapStringsSep "\n" (sys: ''
        mkdir -p "${dataDir}/roms/${sys}"
      '') cfg.systems}

      # BIOS directory
      mkdir -p "${dataDir}/bios"

      # Save directories per emulator
      ${concatMapStringsSep "\n" (emu: ''
        mkdir -p "${dataDir}/saves/${emu}"
      '') cfg.standaloneEmulators}

      # RetroArch-specific save subdirectories
      mkdir -p "${dataDir}/saves/retroarch/saves"
      mkdir -p "${dataDir}/saves/retroarch/states"
    '';
  };
}
