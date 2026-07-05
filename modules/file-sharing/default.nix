{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.file-sharing;

  shareType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the share (visible on network)";
      };
      path = mkOption {
        type = types.path;
        description = "Path to the shared directory";
      };
      validUsers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          List of users allowed to access this share. Ignored when `guestOk`
          is true (the share runs in guest-only mode and per-user auth doesn't
          apply).
        '';
      };
      readOnly = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the share is read-only";
      };
      guestOk = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow anonymous (passwordless) access. When true, the share is
          served in guest-only mode: every connection is mapped to the guest
          account regardless of any username the client supplies, and no
          `smbpasswd` setup is needed. Intended for shares whose security
          comes from the network layer (e.g. tailnet-only `allowedSubnets`)
          rather than per-user credentials.
        '';
      };
      forceUser = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "betongsuggan";
        description = ''
          Force every operation on this share to run as the given system user
          on the filesystem, regardless of which user the client authenticated
          as (or, for guest shares, regardless that nobody authenticated).
          Required for writable guest shares whose backing directory is owned
          by a real user — otherwise the implicit `nobody` identity has no
          permission to create or modify files.
        '';
      };
      deleteProtection = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Protect against accidental or malicious deletion: every `unlink` /
          `rmdir` operation through Samba is transparently redirected into a
          hidden `.recycle/` directory inside the share via Samba's
          `vfs_recycle` module. Writes, updates, renames, and overwrites all
          flow through normally — only deletes are softened. The recycle
          directory is hidden from clients via `veto files`; an operator can
          inspect or purge it over SSH at `<share-path>/.recycle/`.
        '';
      };
    };
  };

  # Convert share list to Samba shares attrset
  mkSambaShares = shares:
    builtins.listToAttrs (map (share: {
      name = share.name;
      value = {
        path = share.path;
        browseable = "yes";
        "read only" = if share.readOnly then "yes" else "no";
        "guest ok" = if share.guestOk then "yes" else "no";
      }
      // (if share.guestOk then {
        "guest only" = "yes";
      } else {
        "valid users" = concatStringsSep " " share.validUsers;
      })
      // (lib.optionalAttrs (share.forceUser != null) {
        "force user" = share.forceUser;
      })
      // (lib.optionalAttrs share.deleteProtection {
        "vfs objects" = "recycle";
        "recycle:repository" = ".recycle";
        "recycle:keeptree" = "yes";
        "recycle:versions" = "yes";
        "recycle:maxsize" = "0";
        "recycle:exclude" = "*.tmp *.temp *.bak ~$*";
        "recycle:exclude_dir" = ".recycle";
        "veto files" = "/.recycle/";
        "hide files" = "/.recycle/";
      });
    }) shares);

in {
  options.file-sharing = {
    enable = mkEnableOption "Enable file sharing";

    samba = {
      enable = mkEnableOption "Enable Samba (SMB) file sharing";

      shares = mkOption {
        type = types.listOf shareType;
        default = [ ];
        description = "List of Samba share definitions";
        example = literalExpression ''
          [
            {
              name = "shared";
              path = "/home/user/shared";
              validUsers = [ "user" ];
              readOnly = false;
            }
          ]
        '';
      };

      workgroup = mkOption {
        type = types.str;
        default = "WORKGROUP";
        description = "Network workgroup name";
      };

      allowedSubnets = mkOption {
        type = types.listOf types.str;
        default = [ "192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12" ];
        description = "Subnets allowed to access Samba shares";
      };

      interfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "tailscale0" ];
        description = ''
          Network interfaces Samba should bind to. Empty list = listen on all
          interfaces (Samba default). Setting this restricts binding to the
          listed interfaces only (`bind interfaces only = yes`), which is
          stronger than `allowedSubnets` alone — Samba won't even open a
          listening socket on other interfaces.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically open firewall ports for Samba";
      };
    };
  };

  config = mkIf cfg.enable {
    # Samba configuration
    services.samba = mkIf cfg.samba.enable {
      enable = true;
      openFirewall = cfg.samba.openFirewall;

      settings = {
        global = {
          workgroup = cfg.samba.workgroup;
          "server string" = "NixOS Samba Server";
          "netbios name" = config.networking.hostName;
          security = "user";

          # Guest shares (guest ok = yes / guest only = yes) accept anonymous
          # (null-session) clients out of the box, but clients that send an
          # explicit username like "guest" (e.g. Solid Explorer on Android)
          # would otherwise be rejected: "user" security tries to authenticate
          # that name, finds no such account, and the default `map to guest =
          # Never` refuses to fall back. Mapping unknown usernames to the guest
          # account makes both anonymous and named-guest logins work.
          "map to guest" = "Bad User";

          # SMB2/SMB3 security (disable SMB1)
          "server min protocol" = "SMB2_10";
          "client min protocol" = "SMB2_10";

          # Restrict access to allowed subnets
          "hosts allow" = concatStringsSep " " (cfg.samba.allowedSubnets ++ [ "127.0.0.1" "localhost" ]);
          "hosts deny" = "0.0.0.0/0";

          # Performance and compatibility
          "use sendfile" = "yes";
          "min receivefile size" = "16384";

          # Disable printing (not needed for file sharing)
          "load printers" = "no";
          printing = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
        } // (lib.optionalAttrs (cfg.samba.interfaces != [ ]) {
          interfaces = concatStringsSep " " cfg.samba.interfaces;
          "bind interfaces only" = "yes";
        });
      } // mkSambaShares cfg.samba.shares;
    };

    # Enable WSDD for network discovery (Windows/Android)
    services.samba-wsdd = mkIf cfg.samba.enable {
      enable = true;
      openFirewall = cfg.samba.openFirewall;
    };

    # Install useful packages
    environment.systemPackages = mkIf cfg.samba.enable (with pkgs; [
      samba
      cifs-utils
    ]);
  };
}
