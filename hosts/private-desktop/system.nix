{ config, lib, pkgs, ... }:

{
  users.users.gamer = {
    isNormalUser = true;
    description = "Gaming User";
    extraGroups = [ "networkmanager" "video" "audio" "input" "gamemode" ];
  };

  users.users.betongsuggan = {
    isNormalUser = true;
    description = "Betongsuggan user";
    #fullName = "Birger Rydback";
    extraGroups =
      [ "wheel" "networkmanager" "network" "video" "docker" "uinput" ];
  };

  # Enable autologin for gaming user using getty method (console autologin)
  autologin = {
    enable = true;
    user = "gamer";
    method = "getty";
    tty = "tty1";
  };
  
  # Disable wayland/display manager entirely for minimal setup
  wayland.enable = false;

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
    
    # Gaming kernel parameters
    kernelParams = [
      # AMD GPU optimizations
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dpm=1"
      # Reduce input latency
      "preempt=full"
      "threadirqs"
      # Memory optimizations
      "transparent_hugepage=madvise"
      # Disable mitigations for performance (security tradeoff)
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

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7bd243d3-6b04-4df9-b4d7-3c590f7ebe3d";
      fsType = "ext4";
    };
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/979c14c3-e740-4c1b-8b3d-cd817ac9b61b"; }];

  services = { 
    fwupd.enable = true;
  };

  # Gaming optimizations
  programs.gamemode.enable = true;
  
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
  printers.enable = true;

  # Enable XDG portals for flatpak
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };
  flatpakSystem.enable = true;
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

  # Game streaming server
  #game-streaming.server.enable = true;
  # System modules
  #firefoxSystem.enable = true;
  #logitech.enable = true;
  #thunarSystem.enable = true;

  # Pin a state version to prevent warnings
  system.stateVersion = "25.05";
}

