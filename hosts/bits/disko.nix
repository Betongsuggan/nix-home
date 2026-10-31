# Framework Laptop 13 Pro internal NVMe, formatted by disko at install time
# (see SPEC.md, "Swap-day runbook"). One LUKS2 container holds LVM, so a
# single passphrase unlocks both the root filesystem and the swap that
# hibernation writes the 32 GB of RAM into.
{ inputs, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk.main = {
      type = "disk";
      # Confirm on the machine (`lsblk`); a by-id path is safer if a second
      # drive ever shows up
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          # Room for lanzaboote's signed kernel images: each generation is a
          # full UKI (kernel + initrd), 10 generations kept
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              content = {
                type = "lvm_pv";
                vg = "vg";
              };
            };
          };
        };
      };
    };

    lvm_vg.vg = {
      type = "lvm_vg";
      lvs = {
        # RAM + 2 GiB: hibernation needs the whole memory image
        swap = {
          size = "34G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
