{ inputs, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    ../../modules/common
    ../../modules/system
    ../../modules/users
    
    # System configuration
    ./system.nix
    
    # User configurations
    ./users.nix
    
    # Apply nixpkgs overlays
    ({ config, lib, pkgs, ... }: {
      nixpkgs = { inherit overlays; };
    })
  ];
}
