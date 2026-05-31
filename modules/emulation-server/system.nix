{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.emulation-server;

  deviceType = types.submodule {
    options = {
      id = mkOption {
        type = types.str;
        description = "Syncthing device ID";
      };
    };
  };

  defaultSystems = [
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

  defaultEmulators = [ "retroarch" "ppsspp" "duckstation" "dolphin" ];

  tmpfilesDir = path: "d ${path} 0775 ${cfg.user} users -";

in
{
  options.emulation-server = {
    enable = mkEnableOption "Emulation server with ROM sharing and save sync";

    user = mkOption {
      type = types.str;
      default = "betongsuggan";
      description = "User account that owns the emulation data";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/emulation";
      description = "Root directory for emulation data (roms, saves, bios)";
    };

    lanInterface = mkOption {
      type = types.str;
      default = "enp1s0";
      description = "LAN network interface that should expose Syncthing/Samba ports";
    };

    lanSubnet = mkOption {
      type = types.str;
      default = "192.168.50.0/24";
      description = "LAN subnet allowed to reach Samba shares";
    };

    systems = mkOption {
      type = types.listOf types.str;
      default = defaultSystems;
      description = "Emulation systems to create ROM subdirectories for";
    };

    standaloneEmulators = mkOption {
      type = types.listOf types.str;
      default = defaultEmulators;
      description = "Standalone emulators to create save subdirectories for";
    };

    syncthing = {
      devices = mkOption {
        type = types.attrsOf deviceType;
        default = { };
        description = "Syncthing devices to sync saves with";
        example = literalExpression ''
          {
            android-phone = { id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX"; };
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Directory layout — owned by the configured user, group writable for Samba/Syncthing.
    systemd.tmpfiles.rules =
      [
        (tmpfilesDir cfg.dataDir)
        (tmpfilesDir "${cfg.dataDir}/roms")
        (tmpfilesDir "${cfg.dataDir}/saves")
        (tmpfilesDir "${cfg.dataDir}/bios")
        (tmpfilesDir "${cfg.dataDir}/saves/retroarch/saves")
        (tmpfilesDir "${cfg.dataDir}/saves/retroarch/states")
      ]
      ++ map (sys: tmpfilesDir "${cfg.dataDir}/roms/${sys}") cfg.systems
      ++ map (emu: tmpfilesDir "${cfg.dataDir}/saves/${emu}") cfg.standaloneEmulators;

    services.syncthing = {
      enable = true;
      user = cfg.user;
      dataDir = cfg.dataDir;
      configDir = "/home/${cfg.user}/.config/syncthing";
      openDefaultPorts = false;

      settings = {
        devices = mapAttrs (_name: device: {
          inherit (device) id;
        }) cfg.syncthing.devices;

        folders = {
          "emulation-saves" = {
            path = "${cfg.dataDir}/saves";
            devices = attrNames cfg.syncthing.devices;
            versioning = {
              type = "simple";
              params.keep = "5";
            };
          };
        };
      };
    };

    file-sharing = {
      enable = true;
      samba = {
        enable = true;
        openFirewall = false;
        allowedSubnets = [ cfg.lanSubnet "100.64.0.0/10" ];
        shares = [
          {
            name = "emulation-roms";
            path = "${cfg.dataDir}/roms";
            readOnly = false;
            guestOk = true;
            forceUser = cfg.user;
            deleteProtection = true;
          }
          {
            name = "emulation-bios";
            path = "${cfg.dataDir}/bios";
            readOnly = false;
            guestOk = true;
            forceUser = cfg.user;
            deleteProtection = true;
          }
        ];
      };
    };

    # Expose Syncthing + Samba only on the LAN and tailnet interfaces.
    networking.firewall.interfaces = {
      ${cfg.lanInterface} = {
        allowedTCPPorts = [ 22000 445 139 ];
        allowedUDPPorts = [ 21027 137 138 ];
      };
      tailscale0 = {
        allowedTCPPorts = [ 22000 445 139 ];
        allowedUDPPorts = [ 21027 137 138 ];
      };
    };
  };
}
