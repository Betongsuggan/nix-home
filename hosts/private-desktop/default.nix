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
        "uinput"
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
        kernelPackages = pkgs.linuxPackages_6_14;
      
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
        kernelModules = [ "iwlwifi" "amdgpu" ];
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
          device = "/dev/disk/by-uuid/7bd243d3-6b04-4df9-b4d7-3c590f7ebe3d";
          fsType = "ext4";
        };
      };
      swapDevices = [
        { device = "/dev/disk/by-uuid/979c14c3-e740-4c1b-8b3d-cd817ac9b61b"; }
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
      starship.enable = true;
      bash.enable = true;
      fonts.enable = true;
      dunst.enable = true;
      kanshi.enable = true;
      thunar.enable = true; 
      hyprland = {
        enable = true;
        monitorResolution = ",3440x1440@100,auto,1";
      };
      wofi.enable = true;

      nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    })
  ];
}
