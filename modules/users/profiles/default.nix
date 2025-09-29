{ lib, config, ... }:

with lib;

{
  # User profile loader
  # This module provides a convenient way to load user profiles
  
  options.userProfile = mkOption {
    type = types.enum [ "desktop" "gaming" "minimal-gaming" ];
    description = "User profile type to load";
    default = "desktop";
  };
  
  config = mkMerge [
    (mkIf (config.userProfile == "desktop") (import ./desktop.nix { inherit lib config; }))
    (mkIf (config.userProfile == "gaming") (import ./gaming.nix { inherit lib config; }))
    (mkIf (config.userProfile == "minimal-gaming") (import ./minimal-gaming.nix { inherit lib config; }))
  ];
}