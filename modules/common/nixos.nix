{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

{
  options.my.common = {
    systemd-boot = mkOption {
      type = types.bool;
      default = true;
      description = "Boot through systemd-boot on UEFI (off for e.g. the Pi's extlinux).";
    };

    accounts = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Login accounts on this host (names in lib.accounts); set by lib/mk-host.nix.";
    };

    admins = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = filter (u: inputs.self.lib.accounts.${u}.admin) config.my.common.accounts;
      description = "The admin accounts on this host; modules add their groups to these.";
    };
  };

  config = {
    users.users = genAttrs config.my.common.accounts (
      u:
      let
        account = inputs.self.lib.accounts.${u};
      in
      {
        isNormalUser = true;
        inherit (account) description;
        extraGroups = optionals account.admin [
          "wheel"
          "video"
        ];
      }
    );

    time.timeZone = mkDefault "Europe/Stockholm";
    console.keyMap = mkDefault "colemak";
    hardware.enableRedistributableFirmware = mkDefault true;

    boot.loader = mkIf config.my.common.systemd-boot {
      systemd-boot = {
        enable = true;
        configurationLimit = mkDefault 10;
      };
      efi.canTouchEfiVariables = mkDefault true;
    };

    # aarch64 builder support: island-pi is deployed with `nixos-rebuild
    # --target-host` from whatever fleet machine is at hand; evaluation and
    # building happen on the deployer (the Pi never builds — see
    # hosts/island-pi/SPEC.md). Gated on x86_64 so aarch64 hosts don't try to
    # emulate themselves.
    boot.binfmt.emulatedSystems = mkIf pkgs.stdenv.hostPlatform.isx86_64 [ "aarch64-linux" ];

    nix = {
      # Enable features in Nix commands
      extraOptions = ''
        experimental-features = nix-command flakes
        warn-dirty = false
      '';

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      settings = {
        # Add community Cachix to binary cache
        builders-use-substitutes = true;
        substituters = [
          "https://nix-community.cachix.org"
          "https://walker.cachix.org"
          "https://niri.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        ];

        auto-optimise-store = true;

        # Parallel build settings for faster rebuilds
        max-jobs = "auto"; # Build multiple derivations in parallel
        cores = 0; # Use all cores per build (0 = auto)
        keep-outputs = true; # Keep build outputs for faster rebuilds
        keep-derivations = true; # Keep .drv files for debugging/rebuilds
        connect-timeout = 5; # Fail faster on unavailable substituters
      };
    };

    # Basic common system packages for all devices
    environment.systemPackages = with pkgs; [
      git
      vim
      wget
      curl
      sshfs
    ];

    # System-side dconf/gsettings plumbing, required for the home-manager
    # stylix gtk/gnome targets' dark-mode preference to reach GTK apps
    programs.dconf.enable = true;

    # sshd defaults for whichever host enables it (tailnet, sops, or the host
    # itself): key-only logins, no root, and no firewall hole unless a host
    # asks for one; tailnet opens 22 on tailscale0 only.
    services.openssh = {
      openFirewall = mkDefault false;
      settings = {
        PasswordAuthentication = mkDefault false;
        PermitRootLogin = mkDefault "no";
      };
    };

    # Controller's SSH host key, trusted on every host so new installs don't
    # hit a TOFU prompt when fetching nix-vault via the tailnet.
    programs.ssh.knownHosts."controller" = {
      hostNames = [
        (inputs.self.lib.tailnet.fqdn "controller")
        "controller"
      ]
      ++ inputs.self.lib.hosts.controller.addresses;
      publicKey = inputs.self.lib.hosts.controller.ssh.host;
    };
  };
}
