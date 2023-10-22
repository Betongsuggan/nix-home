{ config, lib, pkgs,  ... }: {

  options = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary user of the system";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      description = "Human readable name of the user";
    };
    extraUserGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Extra groups for the user";
    };
    userDirs = {
      # Required to prevent infinite recursion when referenced by himalaya
      download = lib.mkOption {
        type = lib.types.str;
        description = "XDG directory for downloads";
        default =
          if pkgs.stdenv.isDarwin then "$HOME/Downloads" else "$HOME/downloads";
      };
    };
  };

  config = {
    # Allows us to declaritively set password
    users.mutableUsers = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.${config.user} = {
      # Create a home directory for human user
      isNormalUser = true;

      extraGroups = [
        "wheel" # Sudo privileges
      ];

    };

    home-manager.users.${config.user}.xdg = {

      # Allow Nix to manage the default applications list
      mimeApps.enable = true;

      # Set directories for application defaults
      userDirs = {
        enable = true;
        createDirectories = true;
        documents = "$HOME/documents";
        download = config.userDirs.download;
        music = "$HOME/media/music";
        pictures = "$HOME/media/images";
        videos = "$HOME/media/videos";
        desktop = "$HOME/other/desktop";
        publicShare = "$HOME/other/public";
        templates = "$HOME/other/templates";
        extraConfig = { XDG_DEV_DIR = "$HOME/dev"; };
      };
    };
  };
}
