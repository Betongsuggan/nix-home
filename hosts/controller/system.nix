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
      # See hosts/controller/SPEC.md for the full flow.
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAII8ur6g8BqxDaC2/PQngQa/eEBHT7RrDtukpiacTByKaAAAADXNzaDpuaXgtdmF1bHQ= yubikey-bootstrap"

      # Daily-driver identity: birgerrydback@bits.
      inputs.self.lib.hosts.bits.ssh.users.birgerrydback.bits
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
  };

  tailscale-client = {
    enable = true;
    loginServer = "https://vpn.rydback.net";
    authKeyFile = config.sops.secrets."headscale-preauthkey".path;
    extraUpFlags = [ "--accept-routes" ];
  };

  # Let the Nix daemon (root) fetch nix-vault over the tailnet using the
  # host's SSH key. Same Match pattern as other hosts.
  programs.ssh.extraConfig = ''
    Match user root host controller.ts.rydback.net
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
  '';

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

  openssh = {
    enable = true;
    openFirewall = false;
  };

  firewall = {
    enable = true;
    tcpPorts = [ ];
    udpPorts = [ ];
  };

  # SSH only reachable over the tailnet — nothing on LAN or WAN.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  git-server = {
    enable = true;
    repositories = [ "nix-vault" ];
    # Every SSH pubkey declared under `hosts.<host>.ssh` in lib/default.nix
    # gets clone/push access. Adding a new user/host key there is enough — no
    # separate enrollment step on controller.
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
    ];
    vhosts.headscale = {
      domain = "vpn.rydback.net";
      upstream = "http://127.0.0.1:8080";
    };
  };

  headscale = {
    enable = true;
    domain = "vpn.rydback.net";
    baseDomain = "ts.rydback.net";
    users = [ "birger" ];
  };

  # Controller is a server — never let it sleep, suspend, or hibernate.
  # Masking the systemd targets is the hard guarantee; logind settings stop
  # power/suspend keys and idle from triggering them in the first place.
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
