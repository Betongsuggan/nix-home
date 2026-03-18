{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      mesa = prev.unstable.mesa;
    })
  ];
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
      "xhci_pci"
      "nvme"
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

    # Add ryzen-smu module for Ryzen CPU monitoring and control
    extraModulePackages = with pkgs.linuxPackages_zen; [ ryzen-smu ];
    kernelModules = [
      "iwlwifi"
      "amdgpu"
      "ryzen_smu"
    ];
    supportedFilesystems = [ "ntfs" ];

    kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dpm=1"
      "amdgpu.dcfeaturemask=0x8" # FreeSync on all displays
      "amdgpu.sg_display=0" # Disable scatter-gather for RDNA4 stability
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
      "usbcore.usbfs_memory_mb=256" # Increase USB memory buffer for KVM USB ethernet
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
    i2c.enable = true;
    sensor.iio.enable = true;
  };

  time.timeZone = "Europe/Stockholm";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7bd243d3-6b04-4df9-b4d7-3c590f7ebe3d";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/4CF6-EC25";
      fsType = "vfat";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/979c14c3-e740-4c1b-8b3d-cd817ac9b61b"; }
  ];

  services = {
    fwupd.enable = true;
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
      # Disable USB autosuspend for VIA Labs hubs (KVM switch)
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2109", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
      # Disable USB autosuspend for Realtek RTL8153 ethernet adapter
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8153", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
    '';
  };

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
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };
  game-streaming.server = {
    enable = true;
    display = "SUNSHINE";
    workspace = 10;
  };

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
      pkgs.xdg-desktop-portal-wlr # For Sunshine WLR capture
    ];
    config.common.default = "*";
  };

  wayland-security.enable = true;
  networkmanager = {
    enable = true;
    hostName = "home-desktop";
  };
  firewall = {
    enable = true;
    tcpPorts = [
      8080
      22000 # Syncthing
      27036
      27037
      53317
    ];
    udpPorts = [
      21027 # Syncthing discovery
      27031
      27032
      27033
      27034
      27035
      27036
      51820 # WireGuard
      53317
    ];
  };
  undervolting.enable = true;

  emulation-server = {
    enable = true;
    user = "gamer";
    dataDir = "/home/gamer/emulation";
    syncthing.devices = { }; # Add device IDs as devices connect
    wireguard = {
      enable = true;
      privateKeyFile = "/etc/wireguard/private.key";
      peers = [ ]; # Add peers later
    };
  };

  system.stateVersion = "25.05";
}
