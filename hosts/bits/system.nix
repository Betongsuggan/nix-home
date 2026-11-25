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
      # The BIOS (0.1.81) declares ASPM unsupported in the FADT, which leaves
      # TLP's PCIE_ASPM_ON_BAT a no-op; force it so links can power down.
      # Suspect for the discrete GPU's remaining probe failures (see
      # initrd.kernelModules): drop it first if `amdgpu 0000:03:00.0` still
      # fails discovery with amdgpu loaded from the initrd
      "pcie_aspm=force"
    ];

    # Early KMS, for the discrete Navi 24 (03:00.0) rather than for the
    # panel: loaded from stage 2 (udev coldplug, 20-35 s in, after the LUKS
    # prompt) amdgpu lost the race against TLP, whose RUNTIME_PM_ON_*=auto
    # applies to the still driverless dGPU and its root port 00:01.1; a
    # driverless endpoint drops to D3cold with its bridge and the probe then
    # reads all-ones ("failed to read discovery info from memory, vram size
    # read: ffffffff"). In the initrd it probes at ~2 s, before any runtime-PM
    # policy exists; amdgpu's own BOCO runtime PM powers it down afterwards.
    # Diagnosed 2026-10-30 over six boots (3 failed, all without the dGPU).
    initrd.kernelModules = [ "amdgpu" ];

    kernel.sysctl = {
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

  # The id_rsa (GitHub) key is stored under a different name in the vault
  sops.secrets."ssh-birgerrydback-id_rsa".key = "users/birgerrydback/ssh/github";

  my.home-network = {
    enable = true;
    mode = "onboarded";
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
    enable = true;
    # Goodix 27c6:658c is supported by libfprint itself (goodixmoc); the
    # Goodix TOD driver doesn't list it
    driver = "generic";
  };
  my.power-management = {
    cpuVendor = "amd";
    gpuVendor = "amd";
    # Raise the firmware power budget only while a game runs (gamemode hook,
    # `gamemoderun %command%`); AC stays on the default balanced profile
    platformProfiles.gaming = "performance";

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
      3010
    ];
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

  # MUX-less hybrid graphics: Hyprland composites on the Rembrandt iGPU
  # (67:00.0); Steam and every game it launches render on the Navi 24
  # (03:00.0) and PRIME-copy to the iGPU. PCI form because renderD* numbering
  # is not stable across boots; if the dGPU is absent Mesa falls back to the
  # iGPU. The Steam client itself keeps the dGPU awake while it is open, so
  # close Steam on battery.
  my.games.steam.env.DRI_PRIME = "pci-0000_03_00_0";
}
