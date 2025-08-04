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
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common
    ../../modules/system
    ../../modules/users
    ({ config, lib, pkgs, ... }: {

      nixpkgs = { inherit overlays; };
      boot = {
        kernelPackages = pkgs.linuxPackages_6_12;
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

        # Graphics and VMs
        kernelModules = [ "kvm-intel" "iwlwifi" ];
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
      touchpad.enable = true;
      graphics = {
        enable = true;
        intel = true;
      };
      audio.enable = true;
      docker.enable = true;
      bluetooth.enable = true;
      wayland.enable = true;
      printers.enable = true;
      power-management.enable = true;

      secrets = {
        enable = true;
        keyProviders = [
          {
            name = "anthropic_key_provider";
            path = "$HOME/.config/anthropic/key_provider.sh";
            envVarName = "ANTHROPIC_API_KEY";
          }
          {
            name = "tavily_key_provider";
            path = "$HOME/.config/tavily/key_provider.sh";
            envVarName = "TAVILY_API_KEY";
          }
        ];
      };
      walker = {
        enable = true;
        runAsService = true;
      };
      networkmanager = {
        enable = true;
        hostName = "nixos";
      };
      firewall = {
        enable = true;
        tcpPorts = [ 8080 ];
      };
      general.enable = true;
      firefox.enable = true;
      games.enable = true;
      communication.enable = true;
      neovim.enable = true;
      bash.enable = true;
      alacritty.enable = true;
      nushell.enable = true;
      starship.enable = true;
      fonts.enable = true;
      dunst.enable = true;
      kanshi.enable = true;
      theme = {
        enable = true;
        wallpaper = ../../assets/wallpaper/zeal.jpg;
      };
      hyprland = {
        enable = true;
        autostartApps = {
          firefox = {
            command = "firefox";
            workspace = 1;
          };

          auto-screen-rotation = {
            command = "auto-screen-rotation";
            workspace = null;
          };

          touchegg = {
            command = "${pkgs.touchegg}/bin/touchegg";
            workspace = null;
          };
        };
      };
      development.enable = true;
      thunar.enable = true;
    })
  ];
}
