{ config, lib, pkgs, ... }:
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

  peerType = types.submodule {
    options = {
      publicKey = mkOption {
        type = types.str;
        description = "WireGuard public key for this peer";
      };
      allowedIPs = mkOption {
        type = types.listOf types.str;
        description = "Allowed IP addresses for this peer";
        example = [ "10.100.0.2/32" ];
      };
    };
  };

in {
  options.emulation-server = {
    enable = mkEnableOption "Emulation server with ROM sharing and save sync";

    user = mkOption {
      type = types.str;
      default = "gamer";
      description = "User account that owns the emulation data";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/home/gamer/emulation";
      description = "Root directory for emulation data (roms, saves, bios)";
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

    wireguard = {
      enable = mkEnableOption "WireGuard VPN for remote emulation access";

      listenPort = mkOption {
        type = types.port;
        default = 51820;
        description = "UDP port for WireGuard";
      };

      address = mkOption {
        type = types.str;
        default = "10.100.0.1/24";
        description = "VPN address for this server";
      };

      privateKeyFile = mkOption {
        type = types.path;
        default = "/etc/wireguard/private.key";
        description = "Path to the WireGuard private key file";
      };

      peers = mkOption {
        type = types.listOf peerType;
        default = [ ];
        description = "WireGuard peers (clients) allowed to connect";
        example = literalExpression ''
          [
            {
              publicKey = "abc123...";
              allowedIPs = [ "10.100.0.2/32" ];
            }
          ]
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Auto-enable the user-side module for the configured user
    home-manager.users.${cfg.user} = { ... }: {
      emulation-server.user = {
        enable = mkDefault true;
        dataDir = mkDefault cfg.dataDir;
      };
    };

    # Syncthing for save file synchronization
    services.syncthing = {
      enable = true;
      user = cfg.user;
      dataDir = cfg.dataDir;
      configDir = "/home/${cfg.user}/.config/syncthing";
      openDefaultPorts = true;

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

    # Samba shares for ROMs and BIOS (read-only) via existing file-sharing module
    file-sharing = {
      enable = true;
      samba = {
        enable = true;
        openFirewall = true;
        shares = [
          {
            name = "emulation-roms";
            path = "${cfg.dataDir}/roms";
            validUsers = [ cfg.user ];
            readOnly = true;
          }
          {
            name = "emulation-bios";
            path = "${cfg.dataDir}/bios";
            validUsers = [ cfg.user ];
            readOnly = true;
          }
        ];
      };
    };

    # WireGuard VPN for remote access
    networking.wireguard.interfaces = mkIf cfg.wireguard.enable {
      wg0 = {
        ips = [ cfg.wireguard.address ];
        listenPort = cfg.wireguard.listenPort;
        privateKeyFile = cfg.wireguard.privateKeyFile;

        peers = map (peer: {
          inherit (peer) publicKey allowedIPs;
        }) cfg.wireguard.peers;
      };
    };

    networking.firewall.allowedUDPPorts =
      mkIf cfg.wireguard.enable [ cfg.wireguard.listenPort ];
  };
}
