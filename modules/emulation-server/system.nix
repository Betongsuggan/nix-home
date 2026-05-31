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
      tailnetFqdn = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Tailnet FQDN of the host that runs this Syncthing instance
          (e.g. `desktop.ts.rydback.net`). Used when `tailnetOnly` is on to
          pin peer addresses to the tailnet. `null` for peers without a
          known tailnet name (typically Android devices that aren't enrolled
          yet) — those fall back to `dynamic` discovery.
        '';
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
      selfSyncthingId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          This host's own Syncthing device ID. When set, the matching entry
          is filtered out of `services.syncthing.settings.devices` since
          Syncthing manages local identity separately from peers — including
          self in the peers list causes warnings or duplicate definitions.
        '';
      };
    };

    tailnetOnly = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Restrict both Syncthing and Samba to the tailnet only. Concretely:
        - Firewall: Syncthing and Samba ports are opened only on `tailscale0`,
          not on `lanInterface`.
        - Samba: binds only to `tailscale0` (`bind interfaces only = yes`)
          and `hosts allow` is reduced to the Headscale tailnet CIDR.
        - Syncthing: global discovery, relays, NAT-PMP, and LAN multicast
          announce are all disabled; peer addresses are pinned to each
          peer's tailnet FQDN.

        Peers must therefore be reachable via the tailnet — entries without
        a `tailnetFqdn` (e.g. Android devices not yet enrolled in the
        tailnet) fall back to `dynamic` discovery and will be unreachable
        while this option is on.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      # Filter out the local device so we don't list ourselves as a peer.
      peerDevices =
        if cfg.syncthing.selfSyncthingId == null then
          cfg.syncthing.devices
        else
          lib.filterAttrs (_: d: d.id != cfg.syncthing.selfSyncthingId) cfg.syncthing.devices;
    in
    {
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
          options = lib.optionalAttrs cfg.tailnetOnly {
            # Tailnet-only mode: no public-internet chatter, no LAN multicast.
            # Peers find each other via the explicit `addresses` below.
            globalAnnounceEnabled = false;
            relaysEnabled = false;
            natEnabled = false;
            localAnnounceEnabled = false;
          };

          devices = mapAttrs (_name: device: {
            id = device.id;
            addresses =
              if cfg.tailnetOnly && device.tailnetFqdn != null then
                [ "tcp://${device.tailnetFqdn}:22000" ]
              else
                [ "dynamic" ];
          }) peerDevices;

          folders = {
            "emulation-saves" = {
              path = "${cfg.dataDir}/saves";
              devices = attrNames peerDevices;
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
          allowedSubnets =
            if cfg.tailnetOnly then [ "100.64.0.0/10" ] else [ cfg.lanSubnet "100.64.0.0/10" ];
          # Intentionally NOT setting samba.interfaces here even in tailnet-only
          # mode: `bind interfaces only = yes` combined with `interfaces =
          # tailscale0` makes smbd panic and nmbd time out at boot, because
          # systemd starts samba before tailscaled has created the tailscale0
          # interface. Restriction to the tailnet is enforced at two layers
          # already (firewall opens samba ports only on tailscale0, `hosts
          # allow` restricts source IPs to 100.64.0.0/10) — those are the
          # actual locks, and binding to all interfaces underneath is fine.
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

      # Expose Syncthing + Samba on the tailnet (always) and the LAN (only
      # when not in tailnet-only mode).
      networking.firewall.interfaces =
        {
          tailscale0 = {
            allowedTCPPorts = [ 22000 445 139 ];
            allowedUDPPorts = [ 21027 137 138 ];
          };
        }
        // lib.optionalAttrs (!cfg.tailnetOnly) {
          ${cfg.lanInterface} = {
            allowedTCPPorts = [ 22000 445 139 ];
            allowedUDPPorts = [ 21027 137 138 ];
          };
        };
    }
  );
}
