{ pkgs, ... }:

{
  users.users.gamer = {
    isNormalUser = true;
    description = "Gaming User";
    extraGroups = [ "networkmanager" "video" "audio" "input" "uinput" "gamemode" ];
  };

  users.users.betongsuggan = {
    isNormalUser = true;
    description = "Betongsuggan user";
    extraGroups =
      [ "wheel" "networkmanager" "network" "video" "docker" "uinput" "input" ];
  };

  autologin = {
    enable = true;
    user = "gamer";
    method = "getty";
    tty = "tty1";
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "freeimage-3.18.0-unstable-2024-04-18" ];
  };

  secure-boot.enable = true;
  boot = {
    # Zen kernel optimized for desktop/gaming performance on Ryzen CPUs
    kernelPackages = pkgs.linuxPackages_zen;

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

    # Add ryzen-smu module for Ryzen CPU monitoring and control
    extraModulePackages = with pkgs.linuxPackages_zen; [ ryzen-smu ];
    kernelModules = [ "iwlwifi" "amdgpu" "ryzen_smu" ];
    supportedFilesystems = [ "ntfs" ];

    kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dpm=1"
      "preempt=full"
      "threadirqs"
      "transparent_hugepage=madvise"
      "mitigations=off"
    ];
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    i2c.enable = true;
    sensor.iio.enable = true;
  };

  time.timeZone = "Europe/Stockholm";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7bd243d3-6b04-4df9-b4d7-3c590f7ebe3d";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/4CF6-EC25";
      fsType = "vfat";
    };
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/979c14c3-e740-4c1b-8b3d-cd817ac9b61b"; }];

  services = { fwupd.enable = true; };

  programs.gamemode.enable = true;
  game-streaming.server = {
    enable = true;
    display = "DP-2";
  };

  environment.systemPackages = with pkgs; [
    iio-sensor-proxy
    home-manager
    gamemode
    mangohud
  ];

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
  console.keyMap = "colemak";
  printers.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr # For Sunshine WLR capture
    ];
    config.common.default = "*";
  };

  wayland-security.enable = true;
  networkmanager = {
    enable = true;
    hostName = "home-desktop";
  };
  firewall = {
    enable = true;
    tcpPorts = [ 8080 27036 27037 ];
    udpPorts = [ 27031 27032 27033 27034 27035 27036 ];
  };
  undervolting.enable = true;

  system.stateVersion = "25.05";
}

