{ inputs, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.lanzaboote.nixosModules.lanzaboote
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
        sharedModules = [
          inputs.walker.homeManagerModules.default
          inputs.stylix.homeModules.stylix
          inputs.vicinae.homeManagerModules.default
        ];
        users.birgerrydback = import ./user-birgerrydback.nix;
      };
    }
  ];
}
