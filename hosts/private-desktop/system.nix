{ config, lib, pkgs, ... }:

{
  # System-level configuration for private-desktop

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "freeimage-3.18.0-unstable-2024-04-18" ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_16;

    initrd.availableKernelModules = [
      "xhci_pci"
      "xhci_hcd"
      "nvme"
      "ahci"
      "usb_storage"
      "sd_mod"
      "usb_storage"
    ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.efiSysMountPoint = "/boot";
      efi.canTouchEfiVariables = true;
      grub.useOSProber = true;
      grub.configurationLimit = 10;
    };

    extraModulePackages = [ pkgs.linuxPackages_6_16.ryzen-smu ];
    kernelModules = [ "iwlwifi" "amdgpu" "ryzen_smu" ];
    supportedFilesystems = [ "ntfs" ];
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    i2c.enable = true;
    sensor.iio.enable = true;
  };

  time.timeZone = "Europe/Stockholm";

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7bd243d3-6b04-4df9-b4d7-3c590f7ebe3d";
      fsType = "ext4";
    };
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/979c14c3-e740-4c1b-8b3d-cd817ac9b61b"; }];

  environment.systemPackages = with pkgs; [ iio-sensor-proxy ];
  services = { fwupd.enable = true; };

  # System modules
  firefox.enable = true;
  graphics = {
    enable = true;
    amd = true;
  };
  audio.enable = true;
  bluetooth = {
    enable = true;
    wake = {
      enable = true;
      allowedDevices = [
        "D0:BC:C1:41:80:04" # DualSense Wireless Controller
      ];
    };
  };
  wayland.enable = true;
  printers.enable = true;
  networkmanager = {
    enable = true;
    hostName = "home-desktop";
  };
  firewall = {
    enable = true;
    tcpPorts = [ 8080 27036 27037 ];
    udpPorts = [ 27031 27032 27033 27034 27035 27036 ];
  };
}

