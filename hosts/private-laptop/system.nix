{ pkgs, ... }:

{
  users.users.betongsuggan = {
    isNormalUser = true;
    description = "Betongsuggan user";
    extraGroups = [ "wheel" "networkmanager" "network" "video" "docker" ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = [ "ntfs" ];
    initrd.availableKernelModules =
      [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;

      efi.efiSysMountPoint = "/boot";
      efi.canTouchEfiVariables = true;
      grub.useOSProber = true;
      grub.configurationLimit = 10;
    };

    kernelModules = [ "kvm-intel" "iwlwifi" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-25.9.0" ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    i2c.enable = true;
    sensor.iio.enable = true;
  };
  game-streaming.client.enable = true;

  time.timeZone = "Europe/Stockholm";

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

  swapDevices =
    [{ device = "/dev/disk/by-uuid/da3b504d-b0fa-450e-8974-e332c5ce5608"; }];

  environment.systemPackages = with pkgs; [ iio-sensor-proxy home-manager ];
  services = { fwupd.enable = true; };

  console.keyMap = "colemak";
  touchpad.enable = true;
  graphics = {
    enable = true;
    intel = true;
  };
  audio.enable = true;
  docker.enable = true;
  bluetooth.enable = true;
  wayland-security.enable = true;
  printers.enable = true;
  power-management.enable = true;

  networkmanager = {
    enable = true;
    hostName = "nixos";
  };
  firewall = {
    enable = true;
    tcpPorts = [ 8080 ];
  };

  system.stateVersion = "25.05";
}
