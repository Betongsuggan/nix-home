{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
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

  # openssh is enabled by home-network/tailnet in onboarded mode, with the
  # firewall closed so sshd is reachable on tailscale0 only.

  my.profiles.gaming-station.enable = true;

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    kernelModules = [
      "iwlwifi"
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/733cebb3-3f57-45b9-826d-e74e577563d3";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3AB6-AEB7";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/c156b693-60e6-43d9-84a0-02f640908350"; }
  ];

  my.sops = {
    enable = true;
    secretsFile = "${inputs.nix-vault}/secrets/island.yaml";
  };

  sops.secrets = {
    "ssh-id-rsa" = {
      key = "users/betongsuggan/ssh/id_rsa";
      owner = "betongsuggan";
      mode = "0600";
      path = "/home/betongsuggan/.ssh/id_rsa";
    };
  };

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  my.graphics.nvidia = true;

  # Tailnet membership. Start in `bootstrap` for the first pass; run
  # `home-network-bootstrap` on the host to join, follow the steps in
  # `modules/home-network/SPEC.md`, then flip to `onboarded` and rebuild.
  my.home-network = {
    enable = true;
    mode = "onboarded";
    authorizeSshFor.betongsuggan = [
      {
        host = "controller";
        user = "betongsuggan";
      }
    ];
  };

  # Wake-on-LAN from island-pi (the always-on relay at the summer place):
  # `ssh island-pi wake-island-stationary`. The MAC lives in lib/default.nix;
  # WoL must also be enabled in BIOS ("Power On By PCI-E" / ErP off).
  # FIXME: placeholder — real NIC name from `ip -br link` on this machine.
  networking.interfaces."eth0".wakeOnLan.enable = true;

  my.network-manager.hostName = "island-stationary";
  networking.firewall = {
    allowedTCPPorts = [
      8080
      53317 # LocalSend
    ];
    allowedUDPPorts = [
      53317 # LocalSend
    ];
  };

  system.stateVersion = "25.05";
}
