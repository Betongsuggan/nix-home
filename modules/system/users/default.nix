{ config, lib, pkgs, ... }:

with lib;

let
  userType = types.submodule {
    options = {
      username = mkOption {
        type = types.str;
        description = "Username for the account";
      };
      
      fullName = mkOption {
        type = types.str;
        description = "Full name of the user";
      };
      
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional groups for the user";
      };
      
      autologin = mkOption {
        type = types.bool;
        default = false;
        description = "Enable autologin for this user";
      };
      
      homeConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Home-manager configuration for this user";
      };
      
      userDirs = {
        download = mkOption {
          type = types.str;
          description = "XDG directory for downloads";
          default = if pkgs.stdenv.isDarwin then "$HOME/Downloads" else "$HOME/downloads";
        };
      };
    };
  };
in

{
  options = {
    # Legacy single user options for backward compatibility
    user = mkOption {
      type = types.str;
      description = "Primary user of the system (legacy)";
      default = "";
    };
    
    fullName = mkOption {
      type = types.str;
      description = "Human readable name of the user (legacy)";
      default = "";
    };
    
    extraUserGroups = mkOption {
      type = types.listOf types.str;
      description = "Extra groups for the user (legacy)";
      default = [];
    };
    
    # New multi-user system
    systemUsers = mkOption {
      type = types.attrsOf userType;
      default = {};
      description = "System users configuration";
    };

    userDirs = {
      download = mkOption {
        type = types.str;
        description = "XDG directory for downloads (legacy)";
        default = if pkgs.stdenv.isDarwin then "$HOME/Downloads" else "$HOME/downloads";
      };
    };
  };

  config = 
    let
      # Create legacy user if defined
      legacyUser = optionalAttrs (config.user != "") {
        ${config.user} = {
          username = config.user;
          fullName = config.fullName;
          extraGroups = config.extraUserGroups;
          autologin = false;
          homeConfig = {};
        };
      };
      
      # Combine legacy and new users
      allUsers = legacyUser // config.systemUsers;
      
      # Find autologin user
      autologinUsers = filterAttrs (name: user: user.autologin) allUsers;
      autologinUser = if length (attrNames autologinUsers) > 0 
                     then head (attrNames autologinUsers) 
                     else null;
    in
    {
      # Allow mutable users for password setting
      users.mutableUsers = true;

      # Create all system users
      users.users = mapAttrs (name: userData: {
        isNormalUser = true;
        description = userData.fullName;
        extraGroups = userData.extraGroups;
      }) allUsers;

      # Configure autologin if any user has it enabled
      autologin = mkIf (autologinUser != null) {
        enable = true;
        user = autologinUser;
      };

      # Legacy user home-manager configuration
      home-manager.users = mkIf (config.user != "") {
        ${config.user} = {
          home.packages = [ pkgs.home-manager ];
          programs.home-manager.enable = true;
          xdg = {
            mimeApps.enable = true;
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
      };
    };
}
