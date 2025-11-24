{ pkgs, lib, ... }:

{
  users.users.birgerrydback = {
    isNormalUser = true;
    description = "Birger Rydback";
    extraGroups = [ "wheel" "networkmanager" "network" "video" "docker" ];
  };

  system.stateVersion = "24.05";
  boot = {
    kernelPackages = pkgs.linuxPackages_6_12;

    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
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

  environment.systemPackages = with pkgs; [ home-manager ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "claude-code" ];
    permittedInsecurePackages = [ "electron-25.9.0" ];
  };

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

  swapDevices =
    [{ device = "/dev/disk/by-uuid/08fd16ed-033c-456a-af0e-f16c933f08a3"; }];

  services.fwupd.enable = true;
  console.keyMap = "colemak";

  touchpad.enable = true;
  backlight.enable = true;
  graphics = {
    enable = true;
    amd = true;
  };
  audio.enable = true;
  networkmanager = {
    enable = true;
    hostName = "bits-nixos";
  };
  docker.enable = true;
  bluetooth.enable = true;
  wayland-security.enable = true;
  printers.enable = true;
  power-management = {
    enable = true;
    powerModes.ac = "powersave";
  };
  firewall = {
    enable = true;
    tcpPorts = [ 8080 ];
  };
  waydroid.enable = true;

  # Enable XDG Desktop Portal for screen sharing
  services.xserver.desktopManager.runXdgAutostartIfNone = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.hyprland.default = [ "hyprland" "gtk" ];
  };
}

