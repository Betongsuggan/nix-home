{ inputs, overlays, ... }:

let
  globals =
    {
      user = "birgerrydback";
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
    inputs.nur.nixosModules.nur
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common
    ../../modules/system
    ../../modules/users
    ({ config, lib, pkgs, ... }: {
      nixpkgs = { inherit overlays; };

      boot = {
     
        kernelPackages = pkgs.linuxPackages_latest;
        
        initrd.availableKernelModules =
          [ "nvme" "xhci_pci" "ahci" "thunderbolt" "usb_storage" "sd_mod" "sdhci_pci" ];
        loader = {
          systemd-boot.enable = true;
          systemd-boot.configurationLimit = 10;
          
          efi.efiSysMountPoint = "/boot";
          efi.canTouchEfiVariables = true;
          grub.useOSProber = true;
          grub.configurationLimit = 10;
        };
      };

      hardware = {
        cpu.amd.updateMicrocode = true;
        enableAllFirmware = true;
        enableRedistributableFirmware = true;
        i2c.enable = true;
      };

      networking = {
        hostName = "bits-nixos";
        
        wireless.enable = false;
        networkmanager.enable = true;
        useDHCP = false;
      };

      nixpkgs.config.allowUnfree = true;

      time.timeZone = "Europe/Stockholm";

      # File systems must be declared in order to boot
      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/75ba9480-26dc-4602-8797-b1896f829acd";
          fsType = "ext4";
        };

        "/boot" = {
          device = "/dev/disk/by-uuid/D4CC-FF5B";
          fsType = "vfat";
        };
      };
      diskEncryption = {
        enable = true;
        diskId = "f3fd4fdf-b8ef-45c7-8e96-2ca5bfe32cd9";
        headerId = "1abd4b51-8a97-4d04-97f1-326b2ef1dcbe";
      };
      swapDevices = [
        { device = "/dev/disk/by-uuid/08fd16ed-033c-456a-af0e-f16c933f08a3"; }
      ];

      services.fwupd.enable = true;

      touchpad.enable = true;
      firefox.enable = true;
      graphics.enable = true;
      audio.enable = true;
      docker.enable = true;
      bluetooth.enable = true;
      wayland.enable = true;
      printers.enable = true;
      power-management.enable = true;
      firewall = {
        enable = true;
        tcpPorts = [ 8080 ];
      };
      git = {
        enable = true;
        userName = "BirgerRydback";
        userEmail = "birger.rydback@bits.bi";
      };
      general.enable = true;
      games.enable = true;
      flatpak.enable = true;
      communication.enable = true;
      neovim.enable = true;
      alacritty.enable = true;
      bash.enable = true;
      fonts.enable = true;
      dunst.enable = true;
      #icons.enable = true;
      kanshi.enable = true;
      #sway.enable = true;
      hyprland.enable = true;
      waybar.enable = true;
      development.enable = true;

      nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    })
  ];
}
