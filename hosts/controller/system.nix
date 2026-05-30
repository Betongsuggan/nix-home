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
    description = "Birger Rydback";
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
    ];
    openssh.authorizedKeys.keys = [
      # Operator's YubiKey (FIDO resident, touch-only). Used during new-host
      # enrollment to SSH in, edit nix-home / nix-vault, and rebuild controller.
      # Kept inline because it's a bootstrap credential, not a tailnet peer.
      # See hosts/controller/SPEC.md for the full flow.
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAII8ur6g8BqxDaC2/PQngQa/eEBHT7RrDtukpiacTByKaAAAADXNzaDpuaXgtdmF1bHQ= yubikey-bootstrap"
      # Tailnet peer keys (e.g. birgerrydback@bits) come from `tailnet.authorizeSshFor` below.
    ];
  };

  system.stateVersion = "25.11";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];

    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  environment.systemPackages = with pkgs; [ home-manager ];

  time.timeZone = "Europe/Stockholm";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/86287dd7-ce44-4bc2-b865-1a008605a68f";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6C50-0273";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/2aa51e50-2e51-46e9-a67c-4d75a5f3c9ad"; }
  ];

  sops-secrets = {
    enable = true;
    secretsFile = "${inputs.nix-vault}/secrets/controller.yaml";
  };

  sops.secrets = {
    "ssh-ed25519" = {
      key = "users/betongsuggan/ssh/id_ed25519";
      owner = "betongsuggan";
      mode = "0600";
      path = "/home/betongsuggan/.ssh/id_ed25519";
    };

    "headscale-preauthkey" = {
      key = "services/headscale-preauthkey";
      owner = "root";
      mode = "0400";
    };

    "vaultwarden-env" = {
      key = "services/vaultwarden-env";
      owner = "vaultwarden";
      mode = "0400";
    };
  };

  tailnet = {
    enable = true;
    authorizeSshFor.betongsuggan = [
      {
        host = "bits";
        user = "birgerrydback";
      }
    ];
  };

  emulation-server = {
    enable = true;
    user = "betongsuggan";
    dataDir = "/var/lib/emulation";
    lanInterface = "enp1s0";
    lanSubnet = "192.168.50.0/24";
    syncthing.devices = { };
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

  wayland-security.enable = true;

  console.keyMap = "colemak";

  graphics = {
    enable = true;
    intel.enable = true;
  };

  audio.enable = true;

  networkmanager = {
    enable = true;
    hostName = "controller";
  };

  networking.networkmanager.ensureProfiles.profiles = {
    enp1s0-static = {
      connection = {
        id = "enp1s0-static";
        type = "ethernet";
        interface-name = "enp1s0";
        autoconnect = true;
        autoconnect-priority = 100;
      };
      ipv4 = {
        method = "manual";
        address1 = "192.168.50.5/24,192.168.50.1";
        dns = "192.168.50.1;1.1.1.1;";
      };
      ipv6.method = "auto";
    };
  };

  firewall = {
    enable = true;
    tcpPorts = [ ];
    udpPorts = [ ];
  };

  git-server = {
    enable = true;
    repositories = [ "nix-vault" ];
    authorizedKeys = inputs.self.lib.allSshKeys ++ [
      # Operator's YubiKey (FIDO resident, touch-only). Kept inline because
      # it's the bootstrap credential used *before* a new host has its own
      # key registered in lib/default.nix. Portable admin credential.
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAII8ur6g8BqxDaC2/PQngQa/eEBHT7RrDtukpiacTByKaAAAADXNzaDpuaXgtdmF1bHQ= yubikey-bootstrap"
    ];
  };

  reverse-proxy = {
    enable = true;
    acmeEmail = "rydback@gmail.com";
    domains = [
      "rydback.net"
      "vpn.rydback.net"
      "vault.rydback.net"
    ];
    vhosts.headscale = {
      domain = "vpn.rydback.net";
      upstream = "http://127.0.0.1:8080";
    };
    vhosts.vaultwarden = {
      domain = "vault.rydback.net";
      upstream = "http://127.0.0.1:8222";
      # Tailnet-only at the nginx layer. Headscale's default prefixes are
      # 100.64.0.0/10 (IPv4) and fd7a:115c:a1e0::/48 (IPv6). ACME HTTP-01
      # challenges still work because NixOS places /.well-known/acme-challenge
      # at a higher-precedence location than `/`.
      extraConfig = ''
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
    };
  };

  vaultwarden = {
    enable = true;
    domain = "vault.rydback.net";
    environmentFile = config.sops.secrets."vaultwarden-env".path;
    # First-run bootstrap: flip to true, rebuild, register operator account at
    # https://vault.rydback.net from a tailnet-connected device, then flip back
    # to false and rebuild. Alternatively, leave false and use /admin (with
    # ADMIN_TOKEN) to invite the first user — the invitation link will land in
    # `journalctl -u vaultwarden` since SMTP isn't configured yet.
    signupsAllowed = false;
  };

  headscale = {
    enable = true;
    domain = "vpn.rydback.net";
    baseDomain = "ts.rydback.net";
    users = [ "birger" ];
    extraDnsRecords = [
      # vault.rydback.net's public A record points at controller's WAN IP so
      # ACME HTTP-01 works. For tailnet members this override resolves it to
      # controller's tailnet IP instead, so requests reach nginx from a 100.x
      # source and clear the deny-all rule on the vault vhost.
      {
        name = "vault.rydback.net";
        type = "A";
        value = "100.64.0.2";
      }
    ];
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  services.logind = {
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
    settings.Login = {
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      IdleAction = "ignore";
    };
  };
}
