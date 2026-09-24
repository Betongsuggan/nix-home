{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  system.stateVersion = "24.05";
  boot = {
    extraModprobeConfig = ''
      options uvcvideo quirks=0x100
    '';

    kernelPackages = pkgs.linuxPackages_6_18;

    kernelParams = [
      "amd_pstate=active" # Modern AMD CPU frequency scaling
    ];

    kernel.sysctl = {
      "vm.laptop_mode" = 5;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.swappiness" = 10;
    };

    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
  };

  nixpkgs.config = {
    permittedInsecurePackages = [
      "electron-25.9.0"
      "nexusmods-app-0.21.1"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/75ba9480-26dc-4602-8797-b1896f829acd";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/52E6-3BEE";
      fsType = "vfat";
    };
  };

  my.disk-encryption = {
    enable = true;
    diskId = "f3fd4fdf-b8ef-45c7-8e96-2ca5bfe32cd9";
    headerId = "ccbec134-bf84-41ad-a903-c99989071e6b";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/08fd16ed-033c-456a-af0e-f16c933f08a3"; }
  ];

  my.sops = {
    enable = true;
    secretsFile = "${inputs.nix-vault}/secrets/bits.yaml";
  };

  sops.secrets = {
    "ssh-bits" = {
      key = "users/birgerrydback/ssh/bits";
      owner = "birgerrydback";
      mode = "0600";
      path = "/home/birgerrydback/.ssh/bits";
    };
    "ssh-id-rsa" = {
      key = "users/birgerrydback/ssh/github";
      owner = "birgerrydback";
      mode = "0600";
      path = "/home/birgerrydback/.ssh/id_rsa";
    };
  };

  my.home-network = {
    enable = true;
    mode = "onboarded";
    authorizeSshFor.birgerrydback = [
      {
        host = "controller";
        user = "betongsuggan";
      }
    ];
  };

  systemd.services.fwupd = {
    wantedBy = lib.mkForce [ ];
  };
  my.profiles.laptop.enable = true;
  my.graphics.amd = true;
  networking.nameservers = [ "1.1.1.1" ];
  # LocalStack API Gateway endpoint used by local development
  networking.extraHosts = ''
    127.0.0.1 bits.execute-api.localhost.localstack.cloud
  '';

  my.docker.enable = true;
  # Disabled 2026-09-17: Waydroid's gralloc allocates on the discrete Navi 24
  # (`gralloc.gbm.device=/dev/dri/renderD128`) while Hyprland composites on the
  # Rembrandt iGPU, so every Android surface crosses GPUs as a DCC-compressed
  # dmabuf. That wedged the iGPU twice in three hours, and Hyprland aborts on
  # GL_UNKNOWN_CONTEXT_RESET because it has no reset-recovery path. Re-enable
  # only after pinning gralloc to the iGPU render node -- see
  # `modules/waydroid/SPEC.md` step 6.
  my.waydroid = {
    enable = false;
    drmSetup = true;
    # Container stays stopped until `waydroid-up`; it only exists for occasional
    # offline Netflix downloads.
    startOnBoot = false;
  };
  my.fingerprint = {
    enable = false;
    clamshellAware = true;
    lidStatePath = "/proc/acpi/button/lid/LID/state";
  };
  my.printers = {
    # Nothing on this network shares a printer; dropping browsed lets cupsd stay
    # socket-activated instead of running from boot.
    remoteDiscovery = false;
  };
  my.power-management = {
    cpuVendor = "amd";
    gpuVendor = "amd";

    # The AC caps and forensics logging that chased the hard power-offs are
    # retired: the telemetry they produced identified the cause (a pack that
    # reports "empty" at 0.5 Wh and then runs for another 100 minutes -- a
    # degraded cell stack plus a fuel gauge that has lost calibration), so the
    # performance cost on AC and the 5-second fdatasync of the telemetry loop
    # no longer buy anything.
  };
  networking.firewall = {
    allowedTCPPorts = [
      8080
      53317
      3010
    ];
    allowedUDPPorts = [ 53317 ];
  };

  my.webcam = {
    enable = true;
    cameras = [
      {
        name = "mx-brio";
        vendorId = "046d";
        productId = "0944";
        settings = {
          brightness = 128;
          contrast = 142;
          saturation = 90;
          sharpness = 114;
          # Discover controls with: v4l2-ctl --list-ctrls-menus
          # Populate after using cameractrls to find preferred values, then rebuild
        };
      }
    ];
  };

  services.xserver.desktopManager.runXdgAutostartIfNone = true;
}
