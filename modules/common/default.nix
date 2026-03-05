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
        max-jobs = "auto";           # Build multiple derivations in parallel
        cores = 0;                   # Use all cores per build (0 = auto)
        keep-outputs = true;         # Keep build outputs for faster rebuilds
        keep-derivations = true;     # Keep .drv files for debugging/rebuilds
        connect-timeout = 5;         # Fail faster on unavailable substituters
      };
    };

    # Basic common system packages for all devices
    environment.systemPackages = with pkgs; [ git vim wget curl ];
  };
}
