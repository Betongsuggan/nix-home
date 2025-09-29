{ lib, config, ... }:

with lib;

let
  desktopProfile = import ./desktop.nix;
  gamingProfile = import ./gaming.nix;
  minimalGamingProfile = import ./minimal-gaming.nix;
in

{
  # User profile loader
  # This module provides a convenient way to load user profiles
  
  options.userProfile = mkOption {
    type = types.nullOr (types.enum [ "desktop" "gaming" "minimal-gaming" ]);
    description = "User profile type to load";
    default = null;
  };
  
  config = mkIf (config.userProfile != null) (mkMerge [
    (mkIf (config.userProfile == "desktop") desktopProfile)
    (mkIf (config.userProfile == "gaming") gamingProfile)
    (mkIf (config.userProfile == "minimal-gaming") minimalGamingProfile)
  ]);
}