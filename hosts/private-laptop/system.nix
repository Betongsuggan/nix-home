{ pkgs, inputs, ... }:

{
  boot = {
    # The default LTS series: far fewer kernel updates than _latest
    kernelPackages = pkgs.linuxPackages;
    supportedFilesystems = [ "ntfs" ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];

    kernelModules = [
      "kvm-intel"
      "iwlwifi"
    ];
  };

  nixpkgs.config = {
    permittedInsecurePackages = [ "electron-25.9.0" ];
  };

  hardware = {
    i2c.enable = true;
    sensor.iio.enable = true;
  };

  # File systems must be declared in order to boot
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/e6fa26ba-7e3a-4146-8bba-54fd65aa211a";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/C8DA-ECD3";
      fsType = "vfat";
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/da3b504d-b0fa-450e-8974-e332c5ce5608"; } ];

  environment.systemPackages = with pkgs; [
    iio-sensor-proxy
  ];

  my.profiles.laptop.enable = true;
  my.power-management.cpuVendor = "intel";
  my.graphics = {
    intel.enable = true;
    # intel.generation = "modern"; # Set to "legacy" or "arc" if needed
  };
  my.docker.enable = true;
  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
  };

  system.stateVersion = "25.05";
}
