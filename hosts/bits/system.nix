{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  users.users.birgerrydback = {
    isNormalUser = true;
    description = "Birger Rydback";
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
      "docker"
      "storage"
    ];
    openssh.authorizedKeys.keys = [
      inputs.self.lib.hosts.controller.ssh.users.betongsuggan.ssh_ed25519
    ];
  };

  system.stateVersion = "24.05";
  boot = {
    extraModprobeConfig = ''
      options uvcvideo quirks=0x100
    '';

    kernelPackages = pkgs.linuxPackages_6_12;

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
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
    permittedInsecurePackages = [
      "electron-25.9.0"
      "nexusmods-app-0.21.1"
    ];
  };

  time.timeZone = "Europe/Stockholm";

  # File systems must be declared in order to boot
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

  diskEncryption = {
    enable = true;
    diskId = "f3fd4fdf-b8ef-45c7-8e96-2ca5bfe32cd9";
    headerId = "ccbec134-bf84-41ad-a903-c99989071e6b";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/08fd16ed-033c-456a-af0e-f16c933f08a3"; }
  ];

  services.fwupd.enable = true;

  sops-secrets = {
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

    "headscale-preauthkey" = {
      key = "services/headscale-preauthkey";
      owner = "root";
      mode = "0400";
    };
  };

  tailscale-client = {
    enable = true;
    loginServer = "https://vpn.rydback.net";
    authKeyFile = config.sops.secrets."headscale-preauthkey".path;
    extraUpFlags = [ "--accept-routes" "--accept-dns" ];
  };

  # Let the Nix daemon (running as root) fetch nix-vault over the tailnet
  # using the host's SSH key. Scoped to root so the user's own SSH config
  # (e.g. birgerrydback's `bits` key) is unaffected.
  programs.ssh.extraConfig = ''
    Match user root host controller.ts.rydback.net
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
  '';

  # Defer fwupd to start on-demand instead of at boot
  systemd.services.fwupd = {
    wantedBy = lib.mkForce [ ];
  };
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
  networking.nameservers = [ "1.1.1.1" ];

  docker.enable = true;
  bluetooth.enable = true;
  fingerprint = {
    enable = false;
    clamshellAware = true;
    lidStatePath = "/proc/acpi/button/lid/LID/state";
  };
  wayland-security.enable = true;
  printers.enable = true;
  power-management = {
    enable = true;
    cpuVendor = "amd";
    gpuVendor = "amd";
  };
  firewall = {
    enable = true;
    tcpPorts = [
      8080
      53317
      3010
    ];
    udpPorts = [ 53317 ];
  };

  webcam = {
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
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.niri-stable ];
  };
}
