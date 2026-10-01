{
  pkgs,
  inputs,
  ...
}:

{
  # openssh is enabled by home-network/tailnet in onboarded mode, with the
  # firewall closed so sshd is reachable on tailscale0 only.

  my.profiles.gaming-station.enable = true;

  boot = {
    # Overrides the profile's zen kernel, pinning it to 7.0.9 — zen 7.1.x drops
    # the USB HID receivers sitting in the monitor's hub behind the GPU's USB-C
    # port. See the nixpkgs-kernel comment in flake.nix.
    #
    # Only the kernel derivation comes from the pinned input; the module set
    # around it is built by the current nixpkgs via linuxPackagesFor, so the
    # NVIDIA driver stays on 26.05's 595.x. Taking the pinned
    # `linuxPackages_zen` wholesale would drag in its 580.x driver, which lacks
    # the `.mod` attribute the 26.05 nvidia module expects.
    #
    # The pinned tree is `import`ed rather than read from `legacyPackages`
    # because out-of-tree modules are built with the *kernel's* stdenv, so its
    # check-meta is what vets the unfree NVIDIA derivation — a bare
    # `legacyPackages` carries a default config and would reject it.
    kernelPackages = pkgs.linuxPackagesFor (
      (import inputs.nixpkgs-kernel {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      }).linuxPackages_zen.kernel
    );

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

    blacklistedKernelModules = [
      # The RTX 2070's Cypress CCGx Type-C controller fails PPM init, leaving
      # the GPU's USB-C port half-managed. Nothing on a desktop needs Type-C
      # port management, and DP alt mode is negotiated by the controller's own
      # firmware — the panel already works today with this driver timing out.
      "ucsi_ccg"
      "typec_ucsi"
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

  # Steam comes from the games module (gamer sets my.games.enable)
  programs.steam.gamescopeSession.enable = true;

  my.graphics.nvidia = true;

  # Tailnet membership. Start in `bootstrap` for the first pass; run
  # `home-network-bootstrap` on the host to join, follow the steps in
  # `modules/home-network/SPEC.md`, then flip to `onboarded` and rebuild.
  my.home-network = {
    enable = true;
    mode = "onboarded";
  };

  # Wake-on-LAN from island-pi (the always-on relay at the summer place):
  # `ssh island-pi wake-island-stationary`. The MAC lives in lib/default.nix;
  # WoL must also be enabled in BIOS ("Power On By PCI-E" / ErP off).
  # FIXME: placeholder — real NIC name from `ip -br link` on this machine.
  networking.interfaces."eth0".wakeOnLan.enable = true;

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
