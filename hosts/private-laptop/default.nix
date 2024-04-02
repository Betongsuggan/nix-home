{ inputs, overlays, ... }:

let
  globals =
    let baseName = "betongsuggan";
    in
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
    inputs.nur.nixosModules.nur
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common
    ../../modules/system
    ../../modules/users
    #{
    #  # disabledModules = [ "misc/news.nix" ];
    #  config = {
    #    news.display = "silent";
    #    news.json = inputs.nixpkgs.lib.mkForce { };
    #    news.entries = inputs.nixpkgs.lib.mkForce [ ];
    #  };
    #}
    ({ config, lib, pkgs, ... }: {
      nixpkgs.overlays = overlays;
      networking.hostName = "nixos";

      networking.wireless.enable = false;
      networking.networkmanager.enable = true;
      networking.useDHCP = false;

      boot.kernelPackages = pkgs.linuxPackages_6_1;

      boot.initrd.availableKernelModules =
        [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;

      boot.loader.efi.efiSysMountPoint = "/boot";
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.grub.useOSProber = true;
      boot.loader.grub.configurationLimit = 10;

      # Graphics and VMs
      boot.kernelModules = [ "kvm-intel" "iwlwifi" ];

      nixpkgs.config.allowUnfree = true;
      hardware.enableAllFirmware = true;
      hardware.enableRedistributableFirmware = true;
      hardware.i2c.enable = true;

      time.timeZone = "Europe/Stockholm";

      nixpkgs.config.permittedInsecurePackages = [
        "electron-25.9.0"
      ];

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
      swapDevices = [
        { device = "/dev/disk/by-uuid/da3b504d-b0fa-450e-8974-e332c5ce5608"; }
      ];

      services.fwupd.enable = true;


      git = {
        enable = true;
        userName = "Betongsuggan";
        userEmail = "rydback@gmail.com";
      };
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
      general.enable = true;
      games.enable = true;
      communication.enable = true;
      neovim.enable = true;
      alacritty.enable = true;
      bash.enable = true;
      fonts.enable = true;
      kanshi.enable = true;
      #sway.enable = true;
      hyprland.enable = true;
      waybar.enable = true;
      development.enable = true;
    })
  ];
}
