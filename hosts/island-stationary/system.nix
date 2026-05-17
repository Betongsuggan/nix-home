{ pkgs, ... }:

{
  users.users.gamer = {
    isNormalUser = true;
    description = "Gaming User";
    extraGroups = [
      "networkmanager"
      "video"
      "audio"
      "input"
      "uinput"
      "gamemode"
    ];
  };

  users.users.betongsuggan = {
    isNormalUser = true;
    description = "Betongsuggan user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
      "docker"
      "uinput"
      "input"
    ];
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
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.efiSysMountPoint = "/boot";
      efi.canTouchEfiVariables = true;
      grub.useOSProber = true;
      grub.configurationLimit = 10;
    };

    kernelModules = [
      "iwlwifi"
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    supportedFilesystems = [ "ntfs" ];

    kernelParams = [
      "nvidia-drm.modeset=1"
      "preempt=full"
      "threadirqs"
      "transparent_hugepage=madvise"
      "mitigations=off"
      "amd_pstate=active" # Modern AMD P-State driver
      "split_lock_detect=off" # Gaming performance
      "tsc=reliable"
      "clocksource=tsc"
      "nowatchdog"
      "nmi_watchdog=0"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.max_map_count" = 2147483642; # Required for some games
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 20;
      "vm.dirty_background_ratio" = 5;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  powerManagement.cpuFreqGovernor = "performance";

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  time.timeZone = "Europe/Stockholm";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/733cebb3-3f57-45b9-826d-e74e577563d3";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3AB6-AEB7";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/c156b693-60e6-43d9-84a0-02f640908350"; }
  ];

  services.fwupd.enable = true;

  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
        ioprio = 0;
        inhibit_screensaver = 1;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    home-manager
    gamemode
    mangohud
  ];

  graphics = {
    enable = true;
    nvidia = true;
  };
  audio = {
    enable = true;
    lowLatency = true;
  };
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
    ];
    config.common.default = "*";
  };

  wayland-security.enable = true;
  networkmanager = {
    enable = true;
    hostName = "island-stationary";
  };
  firewall = {
    enable = true;
    tcpPorts = [
      8080
      53317 # LocalSend
    ];
    udpPorts = [
      53317 # LocalSend
    ];
  };

  system.stateVersion = "25.05";
}
