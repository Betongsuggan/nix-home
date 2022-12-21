{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.diskEncryption;
in {
  options.br.diskEncryption = {
    enable = mkEnableOption "Enable Disk Encryption";

    diskId = mkOption {
      description = "UUID of disk that is encrypted by Luks";
      type = types.str;
    };

    headerId = mkOption {
      description = "UUID of disk that is contains header for encrypted partition";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.luks.devices = {
      crypted = {
        device = "/dev/disk/by-partuuid/${cfg.diskId}";
        header = "/dev/disk/by-partuuid/${cfg.headerId}";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };
}
