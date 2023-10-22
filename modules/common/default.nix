{ config, lib, pkgs, ... }: {

  options = {
  };

  config =
    let stateVersion = "23.05";
    in
    {
      nix = {
        # Enable features in Nix commands
        extraOptions = ''
          experimental-features = nix-command flakes
          warn-dirty = false
        '';

        #gc = {
        #  automatic = true;
        #  options = "--delete-older-than 7d";
        #};

        settings = { # Add community Cachix to binary cache
          builders-use-substitutes = true;
          substituters =
            [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];

          auto-optimise-store = true;
        };
      };

      # Basic common system packages for all devices
      environment.systemPackages = with pkgs; [ git vim wget curl ];

      # Use the system-level nixpkgs instead of Home Manager's
      home-manager.useGlobalPkgs = true;

      # Install packages to /etc/profiles instead of ~/.nix-profile, useful when
      # using multiple profiles for one user
      home-manager.useUserPackages = true;

      # Allow specified unfree packages (identified elsewhere)
      # Retrieves package object based on string name
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) config.unfreePackages;

      # Pin a state version to prevent warnings
      home-manager.users.${config.user}.home.stateVersion = stateVersion;
      home-manager.users.root.home.stateVersion = stateVersion;
    };
}
