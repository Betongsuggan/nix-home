{ pkgs, inputs, ... }:

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
      "render"
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

  sops-secrets = {
    enable = true;
    secretsFile = "${inputs.nix-vault}/secrets/desktop.yaml";
  };

  sops.secrets = {
    "ssh-id-rsa" = {
      key = "users/betongsuggan/ssh/id_rsa";
      owner = "betongsuggan";
      mode = "0600";
      path = "/home/betongsuggan/.ssh/id_rsa";
    };
  };

  home-network = {
    enable = true;
    mode = "onboarded";
    authorizeSshFor.betongsuggan = [
      {
        host = "controller";
        user = "betongsuggan";
      }
      {
        host = "bits";
        user = "birgerrydback";
      }
    ];
  };

  # Auto-mount controller's ROM/BIOS shares for each user that uses the
  # emulation client. Lazy mounts via x-systemd.automount, so unreachable
  # controller is harmless (just an empty dir until access).
  emulation-mounts = {
    enable = true;
    server = inputs.self.lib.tailnet.fqdn "controller";
    users = [ "betongsuggan" ];
  };

  # Receive restic snapshots from controller as the on-site copy in the interim
  # 3-2-1-ish topology. Pubkey sourced from lib (never as a literal); the
  # `restic-controller` system user is chrooted to /var/lib/restic-repos/controller
  # via internal-sftp. See modules/restic-target/SPEC.md.
  restic-target = {
    enable = true;
    sources.controller = {
      sshKey = inputs.self.lib.hosts.controller.users.restic.ssh.id_ed25519;
    };
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
  networking.interfaces.enp12s0f3u3u2.wakeOnLan.enable = true;
  networking.interfaces.enp4s0.wakeOnLan.enable = true;
  ai-server = {
    enable = true;
    models = [
      "qwen3:8b"
      "qwen2.5-coder:14b"
      "qwen2.5-coder:1.5b"
    ];
    comfyui.enable = true;
    voice.enable = true;
  };
  docker.enable = true;
  firewall = {
    enable = true;
    tcpPorts = [
      8080
      27036
      27037
      53317
    ];
    udpPorts = [
      27031
      27032
      27033
      27034
      27035
      27036
      53317
    ];
  };
  undervolting.enable = true;

  # The G13 keypad + thumbstick are grouped by input-remapper under a single
  # device group named "Logitech G13 Thumbstick". All mappings (G-keys and
  # thumbstick) go in one preset.
  inputRemapper = {
    enable = true;
    devices."Logitech G13 Thumbstick" = {
      preset = "g13";
      mappings = [
        # Thumbstick -> WASD
        {
          input = [
            {
              type = 3;
              code = 1;
              analog_threshold = -40;
            }
          ];
          output = "KEY_W";
        } # Up
        {
          input = [
            {
              type = 3;
              code = 1;
              analog_threshold = 40;
            }
          ];
          output = "KEY_S";
        } # Down
        {
          input = [
            {
              type = 3;
              code = 0;
              analog_threshold = -40;
            }
          ];
          output = "KEY_A";
        } # Left
        {
          input = [
            {
              type = 3;
              code = 0;
              analog_threshold = 40;
            }
          ];
          output = "KEY_D";
        } # Right
        # G1-G10 -> 1-0
        {
          input = [
            {
              type = 1;
              code = 656;
            }
          ];
          output = "KEY_1";
        } # G1
        {
          input = [
            {
              type = 1;
              code = 657;
            }
          ];
          output = "KEY_2";
        } # G2
        {
          input = [
            {
              type = 1;
              code = 658;
            }
          ];
          output = "KEY_3";
        } # G3
        {
          input = [
            {
              type = 1;
              code = 659;
            }
          ];
          output = "KEY_4";
        } # G4
        {
          input = [
            {
              type = 1;
              code = 660;
            }
          ];
          output = "KEY_5";
        } # G5
        {
          input = [
            {
              type = 1;
              code = 661;
            }
          ];
          output = "KEY_6";
        } # G6
        {
          input = [
            {
              type = 1;
              code = 662;
            }
          ];
          output = "KEY_7";
        } # G7
        {
          input = [
            {
              type = 1;
              code = 663;
            }
          ];
          output = "KEY_TAB";
        } # G8
        {
          input = [
            {
              type = 1;
              code = 664;
            }
          ];
          output = "KEY_9";
        } # G9
        {
          input = [
            {
              type = 1;
              code = 665;
            }
          ];
          output = "KEY_0";
        } # G10
        # G11-G22 -> F1-F12
        {
          input = [
            {
              type = 1;
              code = 666;
            }
          ];
          output = "KEY_F1";
        } # G11
        {
          input = [
            {
              type = 1;
              code = 667;
            }
          ];
          output = "KEY_F2";
        } # G12
        {
          input = [
            {
              type = 1;
              code = 668;
            }
          ];
          output = "KEY_F3";
        } # G13
        {
          input = [
            {
              type = 1;
              code = 669;
            }
          ];
          output = "KEY_F4";
        } # G14
        {
          input = [
            {
              type = 1;
              code = 670;
            }
          ];
          output = "KEY_LEFTSHIFT";
        } # G15
        {
          input = [
            {
              type = 1;
              code = 671;
            }
          ];
          output = "KEY_F6";
        } # G16
        {
          input = [
            {
              type = 1;
              code = 672;
            }
          ];
          output = "KEY_F7";
        } # G17
        {
          input = [
            {
              type = 1;
              code = 673;
            }
          ];
          output = "KEY_F8";
        } # G18
        {
          input = [
            {
              type = 1;
              code = 674;
            }
          ];
          output = "KEY_F9";
        } # G19
        {
          input = [
            {
              type = 1;
              code = 675;
            }
          ];
          output = "KEY_F10";
        } # G20
        {
          input = [
            {
              type = 1;
              code = 676;
            }
          ];
          output = "KEY_F11";
        } # G21
        {
          input = [
            {
              type = 1;
              code = 677;
            }
          ];
          output = "KEY_F12";
        } # G22
        # Thumbstick buttons -> modifiers
        {
          input = [
            {
              type = 1;
              code = 294;
            }
          ];
          output = "KEY_LEFTCTRL";
        } # Left button
        {
          input = [
            {
              type = 1;
              code = 295;
            }
          ];
          output = "KEY_ESC";
        } # Right button
      ];
    };
  };

  system.stateVersion = "25.05";
}
