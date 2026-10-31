{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./disko.nix
    # Framework's quirks for the 13 Pro (their NixOS guide asks for it): EC
    # kernel module and framework-tool (charge limit, LEDs), ambient light
    # sensor, NVMe idle power, Ethernet card autosuspend
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
  ];

  system.stateVersion = "24.05";
  boot = {
    extraModprobeConfig = ''
      options uvcvideo quirks=0x100
    '';

    # Panther Lake (Core Ultra X9, Arc B390 on the xe driver) improves with
    # every kernel from 7.0 on; track the newest instead of an LTS pin
    kernelPackages = pkgs.linuxPackages_latest;

    # zswap: compressed RAM cache in front of the swap LV (disko.nix), which
    # stays the hibernation target
    kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=20"
    ];

    kernel.sysctl = {
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.swappiness" = 10;
    };

    # Expected for the Framework 13 Pro; replace with what
    # `nixos-generate-config --show-hardware-config` reports on the machine
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
    ];
  };

  # zswap already compresses in front of the swap LV; the laptop profile's
  # zram would compress the same pages a second time
  zramSwap.enable = false;

  # Straight to the default entry; hold a key during boot for the menu
  boot.loader.timeout = 0;

  # A hung stop job (once a session scope with nvim: 90 s, killed at the
  # default timeout) shouldn't hold a shutdown for long; 10 s for the system
  # and the user manager
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  systemd.user.extraConfig = "DefaultTimeoutStopSec=10s";

  # Option manuals are evaluated on every rebuild (~7 s of ~35); `man` for
  # the installed tools stays
  documentation.nixos.enable = false;

  hardware.i2c.enable = true;

  nixpkgs.config = {
    permittedInsecurePackages = [
      "electron-25.9.0"
      "nexusmods-app-0.21.1"
    ];
  };

  # Filesystems, LUKS and swap come from disko.nix
  my.secure-boot.enable = true;

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
  my.graphics.intel = {
    enable = true;
    generation = "xe";
  };
  # The nixos-hardware module defaults to i915 in the initrd and both VA-API
  # drivers plus intel-ocl; Panther Lake runs on xe with iHD only
  hardware.intelgpu = {
    driver = "xe";
    vaapiDriver = "intel-media-driver";
  };
  networking.nameservers = [ "1.1.1.1" ];
  # LocalStack API Gateway endpoint used by local development
  networking.extraHosts = ''
    127.0.0.1 bits.execute-api.localhost.localstack.cloud
  '';

  my.docker.enable = true;
  # Off: only ever used for offline Netflix downloads. The old laptop's
  # reason (Android surfaces crossing from its discrete GPU to the iGPU and
  # resetting it) doesn't exist on this single-GPU machine; see
  # modules/waydroid/SPEC.md before turning it on
  my.waydroid = {
    enable = false;
    drmSetup = true;
    # Container stays stopped until `waydroid-up`; it only exists for occasional
    # offline Netflix downloads.
    startOnBoot = false;
  };
  my.fingerprint = {
    enable = true;
    # Framework's Goodix reader; expected to be supported by libfprint itself
    # like the old laptop's 27c6:658c. Confirm the id (`lsusb | grep 27c6`)
    driver = "generic";
  };
  my.power-management = {
    cpuVendor = "intel";
    gpuVendor = "intel";
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
}
