{ inputs, overlays, ... }:

let
  globals =
    {
      user = "betongsuggan";
      fullName = "Birger Rydback";
      extraUserGroups = [
        "wheel"
        "networkmanager"
        "network"
        "video"
        "docker"
      ];
    };
in
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    globals
    ../../modules/users/theming
    inputs.nur.modules.nixos.default
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common
    ../../modules/system
    ../../modules/users
    ({ config, lib, pkgs, ... }: {

      nixpkgs = { inherit overlays; };
      boot = {
        kernelPackages = pkgs.linuxPackages_6_6;
      
        initrd.availableKernelModules =
          [ "xhci_pci" "xhci_hcd" "nvme" "ahci" "usb_storage" "sd_mod" "usb_storage" ];
        loader = {
          systemd-boot.enable = true;
          systemd-boot.configurationLimit = 10;
        
          efi.efiSysMountPoint = "/boot";
          efi.canTouchEfiVariables = true;
          grub.useOSProber = true;
          grub.configurationLimit = 10;
        };
      
        # Graphics and VMs
        kernelModules = [ "iwlwifi" ];
        supportedFilesystems = [ "ntfs" ];
      };

      nixpkgs.config.allowUnfree = true;
      hardware = {
        enableAllFirmware = true;
        enableRedistributableFirmware = true;
        i2c.enable = true;
        sensor.iio.enable = true;
      };

      time.timeZone = "Europe/Stockholm";

      # File systems must be declared in order to boot
      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/43255a91-0948-4139-a4b6-8dfd39d0cb71";
          fsType = "ext4";
        };
      };
      swapDevices = [
        { device = "/dev/disk/by-uuid/e60bcff0-9a13-4d4b-8b4d-9942f317ecd0"; }
      ];


      environment.systemPackages = with pkgs; [ 
        iio-sensor-proxy 
      ];
      services = {
        fwupd.enable = true;
      };

      git = {
        enable = true;
        userName = "Betongsuggan";
        userEmail = "rydback@gmail.com";
      };
      ai = {
        enable = true;
        keyProviderPath = "$HOME/.config/anthropic/key_provider.sh";
      };
      firefox.enable = true;
      graphics = {
        enable = true;
        nvidia = true;
      };
      audio.enable = true;
      bluetooth.enable = true;
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
      general.enable = true;
      game-streaming.server.enable = true;
      neovim.enable = true;
      games.enable = true;
      communication.enable = true;
      alacritty.enable = true;
      bash.enable = true;
      fonts.enable = true;
      dunst.enable = true;
      kanshi.enable = true;
      thunar.enable = true; 
      hyprland.enable = true;
      wofi.enable = true;

      nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    })
  ];
}
