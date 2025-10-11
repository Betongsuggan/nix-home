{ lib, pkgs, ... }: {
  options = {
    unfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of unfree packages to allow.";
      default = [ ];
    };
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "Applied state version for Nix packages";
      default = "24.11";
    };
  };

  config = {
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

      settings = {
        # Add community Cachix to binary cache
        builders-use-substitutes = true;
        substituters =
          [ "https://nix-community.cachix.org" "https://walker.cachix.org" ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        ];

        auto-optimise-store = true;
      };
    };

    # Basic common system packages for all devices
    environment.systemPackages = with pkgs; [ git vim wget curl ];
  };
}
