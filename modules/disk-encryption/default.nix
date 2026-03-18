{ config, lib, pkgs, ... }:
with lib;

{
  options.diskEncryption = {
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

  config = mkIf config.diskEncryption.enable {
    boot.initrd.luks.devices = {
      crypted = {
        device = "/dev/disk/by-partuuid/${config.diskEncryption.diskId}";
        header = "/dev/disk/by-partuuid/${config.diskEncryption.headerId}";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };
}
