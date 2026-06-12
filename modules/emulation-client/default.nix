{ config, lib, pkgs, inputs, ... }:
with lib;

let
  cfg = config.emulation-client;
  controllerSyncthingId = inputs.self.lib.hosts.controller.users.betongsuggan.syncthing.id;
  controllerTailnetFqdn = inputs.self.lib.tailnet.fqdn "controller";

  mountScript = pkgs.writeShellScriptBin "mount-emulation-roms" ''
    SERVER="''${1:-${cfg.server.address}}"
    MOUNT_BASE="''${HOME}/emulation"

    echo "Mounting emulation shares from $SERVER..."

    sudo mkdir -p "$MOUNT_BASE/roms" "$MOUNT_BASE/bios"

    echo "Mounting ROMs..."
    sudo mount -t cifs "//$SERVER/emulation-roms" "$MOUNT_BASE/roms" \
      -o "guest,uid=$(id -u),gid=$(id -g)"

    echo "Mounting BIOS..."
    sudo mount -t cifs "//$SERVER/emulation-bios" "$MOUNT_BASE/bios" \
      -o "guest,uid=$(id -u),gid=$(id -g)"

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
        default = "desktop";
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
    # Syncthing for save file synchronization. Controller is declared as a
    # known peer up-front and the shared folder is pre-configured, so the
    # daemon comes up already paired — no web-UI clicking needed on rebuild.
    services.syncthing = {
      enable = true;
      settings = {
        devices.controller = {
          id = controllerSyncthingId;
          addresses = [ "tcp://${controllerTailnetFqdn}:22000" ];
        };
        folders.emulation-saves = {
          path = cfg.savesDir;
          devices = [ "controller" ];
          type = "sendreceive";
          versioning = {
            type = "simple";
            params.keep = "5";
          };
        };
      };
    };

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
