{ inputs, overlays, ... }:

let
  globals = {
    user = "birgerrydback";
    fullName = "Birger Rydback";
    extraUserGroups = [ "wheel" "networkmanager" "network" "video" "docker" ];
  };
in inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    globals
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    ../../modules/common
    ../../modules/system

    ./system.nix

    ({ config, lib, pkgs, ... }: {
      nixpkgs = { inherit overlays; };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs overlays; };
        users.birgerrydback = import ./user-birgerrydback.nix;
      };
    })
  ];
}
