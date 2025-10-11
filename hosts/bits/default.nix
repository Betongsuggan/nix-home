{ inputs, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    inputs.home-manager.nixosModules.home-manager
    ../../modules/common
    ../../modules/system

    ./system.nix

    {
      nixpkgs = {
        inherit overlays;
        config = { allowUnfree = true; };
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs overlays; };
        sharedModules = [ inputs.walker.homeManagerModules.default ];
        users.birgerrydback = import ./user-birgerrydback.nix;
      };
    }
  ];
}
