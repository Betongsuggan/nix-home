{ inputs, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    ../../modules/common
    ../../modules/system

    ./system.nix

    # Home Manager configurations moved to standalone flake homeConfigurations

    ({ config, lib, pkgs, ... }: { nixpkgs = { inherit overlays; }; })
  ];
}
