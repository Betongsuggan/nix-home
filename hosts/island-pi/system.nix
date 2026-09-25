{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # Deploys run as root over SSH (nixos-rebuild --target-host root@…) and must
  # work from ANY fleet machine, so every human user key is authorized. This is
  # the same expansion modules/home-network does from sshFrom — inlined here
  # because it must also hold in stage 1, before home-network is enabled.
  # Deliberately not allUserPeers: that would include service identities like
  # controller's restic user.
  deployKeys = lib.concatMap (
    p: lib.collect lib.isString (inputs.self.lib.hosts.${p.host}.users.${p.user}.ssh or { })
  ) (inputs.self.lib.allPeersFor "betongsuggan" ++ inputs.self.lib.allPeersFor "birgerrydback");
in
{
  system.stateVersion = "26.05";

  i18n.defaultLocale = "en_GB.UTF-8";

  # --- Raspberry Pi 3 Model B boot & hardware ---------------------------------
  # U-Boot + extlinux, mainline kernel (default linuxPackages). The SD card is
  # partitioned by the sd-image build (see packages.aarch64-linux in flake.nix):
  # vfat FIRMWARE partition with Pi firmware + U-Boot, ext4 NIXOS_SD root.
  # Rebuilds only rewrite /boot/extlinux on the root partition — the firmware
  # partition is never touched by deploys.
  my.common.systemd-boot = false;
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.initrd.availableKernelModules = [
    "mmc_block"
    "usbhid"
    "usb_storage"
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "nofail"
        "noauto"
      ];
    };
  };

  # 1 GB RAM: compressed swap in RAM instead of swapping to the SD card.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  # SD-card friendliness: cap the persistent journal.
  services.journald.extraConfig = ''
    SystemMaxUse=100M
  '';

  # Wired only, plain DHCP — no NetworkManager on a headless single-NIC host.
  networking.useDHCP = lib.mkDefault true;

  # --- Access ----------------------------------------------------------------
  users.users.betongsuggan.openssh.authorizedKeys.keys = deployKeys;

  # Wheel group can sudo without re-typing password — pragmatic for a single
  # operator over SSH; protected by SSH key auth.
  security.sudo.wheelNeedsPassword = false;

  users.users.root.openssh.authorizedKeys.keys = deployKeys;

  services.openssh = {
    enable = true;
    # Stays open on the LAN even after tailnet enrollment (the recovery path
    # when the tailnet is down; see the firewall rule below).
    openFirewall = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  networking.firewall = {
    # 22 stays open on the LAN permanently: the no-truck-roll recovery path at
    # the summer place if the tailnet is down. Key-only auth.
    allowedTCPPorts = [ 22 ];
  };

  # --- Wake-on-LAN relay -------------------------------------------------------
  # Wake island-stationary over the summer-place LAN, then ssh it directly via
  # its own tailnet address: `ssh island-pi wake-island-stationary`.
  environment.systemPackages = [
    pkgs.wakeonlan
    (pkgs.writeShellScriptBin "wake-island-stationary" ''
      exec ${pkgs.wakeonlan}/bin/wakeonlan ${inputs.self.lib.hosts.island-stationary.wol.mac}
    '')
  ];

  # --- Stage 2 (uncomment after nix-vault enrollment; see SPEC.md) ------------
  # This host never evaluates nix itself, so it skips bootstrap mode entirely:
  # the deploying machine fetches nix-vault, the Pi only needs its host key
  # registered as an age recipient so sops can decrypt at activation.
  #
  # my.home-network = {
  #   enable = true;
  #   mode = "onboarded";
  # };
  #
  # my.sops = {
  #   enable = true;
  #   secretsFile = "${inputs.nix-vault}/secrets/island-pi.yaml";
  # };
  #
  # # Subnet router: advertise the summer-place LAN to the tailnet. Applied at
  # # registration only; routes must be approved on controller (see SPEC.md).
  # my.home-network.advertiseRoutes = [ "192.168.0.0/24" ]; # FIXME: real summer-place subnet
}
