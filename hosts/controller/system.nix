{ pkgs, lib, ... }:

{
  users.users.betongsuggan = {
    isNormalUser = true;
    description = "Birger Rydback";
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
    ];
  };

  system.stateVersion = "25.11";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];

    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  environment.systemPackages = with pkgs; [ home-manager ];

  time.timeZone = "Europe/Stockholm";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/86287dd7-ce44-4bc2-b865-1a008605a68f";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6C50-0273";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/2aa51e50-2e51-46e9-a67c-4d75a5f3c9ad"; }
  ];

  services.xserver.desktopManager.runXdgAutostartIfNone = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.niri-stable ];
  };

  wayland-security.enable = true;

  console.keyMap = "colemak";

  graphics = {
    enable = true;
    intel.enable = true;
  };

  audio.enable = true;

  networkmanager = {
    enable = true;
    hostName = "controller";
  };

  openssh = {
    enable = true;
    openFirewall = true;
  };

  firewall = {
    enable = true;
    tcpPorts = [ ];
    udpPorts = [ ];
  };
}
