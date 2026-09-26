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

    host = mkOption {
      type = types.str;
      description = "This host's name in lib.hosts (set by lib/mk-host.nix).";
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

    # Bounded journal (hosts can set their own)
    services.journald.extraConfig = mkDefault ''
      SystemMaxUse=200M
    '';

    boot.loader = mkIf config.my.common.systemd-boot {
      systemd-boot = {
        enable = true;
        configurationLimit = mkDefault 10;
      };
      efi.canTouchEfiVariables = mkDefault true;
      # Show the menu for 1 s (press a key to stop it) instead of 5
      timeout = mkDefault 1;
    };

    # aarch64 builder support: island-pi is deployed with `nixos-rebuild
    # --target-host` from whatever fleet machine is at hand; evaluation and
    # building happen on the deployer (the Pi never builds — see
    # hosts/island-pi/SPEC.md). Gated on x86_64 so aarch64 hosts don't try to
    # emulate themselves.
    boot.binfmt.emulatedSystems = mkIf pkgs.stdenv.hostPlatform.isx86_64 [ "aarch64-linux" ];

    # /tmp is on disk, not tmpfs (builds such as Go's need more room than RAM
    # should hold), so whatever killed builds leave behind would otherwise
    # pile up forever
    boot.tmp.cleanOnBoot = mkDefault true;

    nix = {
      # Enable features in Nix commands
      extraOptions = ''
        experimental-features = nix-command flakes
        warn-dirty = false
      '';

      # Weekly GC and store deduplication. Both catch up after a missed run
      # (persistent timers), so they are spread out and run at idle CPU/IO
      # priority instead of competing with the session right after boot.
      gc = {
        automatic = true;
        dates = "weekly";
        randomizedDelaySec = "45min";
        options = "--delete-older-than 14d";
      };
      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };

      settings = {
        # Add community Cachix to binary cache
        builders-use-substitutes = true;
        substituters = [
          "https://nix-community.cachix.org"
          "https://walker.cachix.org"
          "https://niri.cachix.org"
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];

        # Parallel builds: every derivation may use all cores; profiles cap
        # how many run at once (laptops)
        max-jobs = mkOptionDefault "auto";
        cores = 0;
        connect-timeout = 5; # Fail faster on unavailable substituters
      };
    };

    systemd.services = genAttrs [ "nix-gc" "nix-optimise" ] (_: {
      serviceConfig = {
        Nice = 19;
        IOSchedulingClass = "idle";
        CPUSchedulingPolicy = "idle";
      };
    });

    # Basic common system packages for all devices, plus `wake-<host>` for
    # every host this one wakes (lib.hosts.<host>.wol.relay): the relay sits
    # on the target's LAN, where the magic packet has to be sent, e.g.
    # `ssh controller wake-desktop`
    environment.systemPackages =
      with pkgs;
      [
        git
        vim
        wget
        curl
        sshfs
      ]
      ++ mapAttrsToList (
        name: h: writeShellScriptBin "wake-${name}" "exec ${wakeonlan}/bin/wakeonlan ${h.wol.mac}"
      ) (filterAttrs (_: h: (h.wol.relay or null) == config.my.common.host) inputs.self.lib.hosts);

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
