{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.disk-encryption = {
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

  config = mkIf config.my.disk-encryption.enable {
    boot.initrd.luks.devices = {
      crypted = {
        device = "/dev/disk/by-partuuid/${config.my.disk-encryption.diskId}";
        header = "/dev/disk/by-partuuid/${config.my.disk-encryption.headerId}";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };
}
