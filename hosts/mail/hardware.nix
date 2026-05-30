{ lib, ... }:

{
  # Hetzner Cloud x86 VMs expose a single virtio disk (/dev/sda) and boot UEFI.
  # disko declares the partition layout so nixos-anywhere can format and mount
  # it during the initial install.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };

    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "virtio_net"
      "ahci"
      "sd_mod"
      "sr_mod"
    ];

    kernelModules = [ "kvm-intel" ];
  };

  # Hetzner Cloud assigns IPv4 + IPv6 via DHCP / RA on the single NIC.
  networking.useDHCP = lib.mkDefault true;
}
