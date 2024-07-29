{ inputs, overlays, ... }:

let
  globals =
    {
      user = "betongsuggan";
      fullName = "Birger Rydback";
      extraUserGroups = [
        "wheel"
        "networkmanager"
        "video"
        "docker"
      ];
    };
in
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    globals
    {
      _module.args = { inherit inputs; };
    }
    inputs.nur.nixosModules.nur
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common
    ../../modules/system
    ../../modules/users
    ({ config, lib, pkgs, ... }: {

      nixpkgs = { inherit overlays; };
      boot = {
        kernelPackages = pkgs.linuxPackages_6_1;
      
        initrd.availableKernelModules =
          [ "xhci_pci" "nvme" "ahci" "usb_storage" "sd_mod" "usb_storage" ];
        loader = {
          systemd-boot.enable = true;
          systemd-boot.configurationLimit = 10;
        
          efi.efiSysMountPoint = "/boot";
          efi.canTouchEfiVariables = true;
          grub.useOSProber = true;
          grub.configurationLimit = 10;
        };
      
        # Graphics and VMs
        kernelModules = [ "kvm-amd" "iwlwifi" ];
      };

      nixpkgs.config.allowUnfree = true;
      hardware = {
        enableAllFirmware = true;
        enableRedistributableFirmware = true;
        i2c.enable = true;
        sensor.iio.enable = true;
      };

      time.timeZone = "Europe/Stockholm";

      nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
      ];

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
        tcpPorts = [ 8080 ];
      };
      general.enable = true;
      games.enable = true;
      communication.enable = true;
      neovim.enable = true;
      alacritty.enable = true;
      bash.enable = true;
      fonts.enable = true;
      dunst.enable = true;
      kanshi.enable = true;
      hyprland.enable = true;
      development.enable = true;
      wofi.enable = true;
    })
  ];
}
