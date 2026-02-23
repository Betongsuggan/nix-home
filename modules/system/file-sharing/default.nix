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
        description = "List of users allowed to access this share";
      };
      readOnly = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the share is read-only";
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
        "guest ok" = "no";
        "valid users" = concatStringsSep " " share.validUsers;
      };
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
        };
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
