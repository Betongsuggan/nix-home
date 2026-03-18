{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.emulation-client;

  mountScript = pkgs.writeShellScriptBin "mount-emulation-roms" ''
    SERVER="''${1:-${cfg.server.address}}"
    MOUNT_BASE="''${HOME}/emulation"
    USER="''${2:-$(whoami)}"

    echo "Mounting emulation shares from $SERVER..."

    sudo mkdir -p "$MOUNT_BASE/roms" "$MOUNT_BASE/bios"

    echo "Mounting ROMs..."
    sudo mount -t cifs "//$SERVER/emulation-roms" "$MOUNT_BASE/roms" \
      -o "username=$USER,uid=$(id -u),gid=$(id -g),ro"

    echo "Mounting BIOS..."
    sudo mount -t cifs "//$SERVER/emulation-bios" "$MOUNT_BASE/bios" \
      -o "username=$USER,uid=$(id -u),gid=$(id -g),ro"

    echo "Done. ROMs at $MOUNT_BASE/roms, BIOS at $MOUNT_BASE/bios"
  '';

in {
  options.emulation-client = {
    enable = mkEnableOption "Emulation client (save sync + ROM access)";

    savesDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/emulation/saves";
      description = "Local directory for synced save files";
    };

    server = {
      address = mkOption {
        type = types.str;
        default = "home-desktop";
        description = "Address of the emulation server (hostname or IP)";
      };
    };

    standaloneEmulators = mkOption {
      type = types.listOf types.str;
      default = [ "retroarch" "ppsspp" "duckstation" "dolphin" ];
      description = "Standalone emulators to create save subdirectories for";
    };
  };

  config = mkIf cfg.enable {
    # Syncthing for save file synchronization
    services.syncthing.enable = true;

    home.packages = [
      pkgs.cifs-utils
      mountScript
    ];

    # Create local save directory structure
    home.activation.createEmulationClientDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${concatMapStringsSep "\n" (emu: ''
        mkdir -p "${cfg.savesDir}/${emu}"
      '') cfg.standaloneEmulators}

      # RetroArch-specific save subdirectories
      mkdir -p "${cfg.savesDir}/retroarch/saves"
      mkdir -p "${cfg.savesDir}/retroarch/states"
    '';
  };
}
