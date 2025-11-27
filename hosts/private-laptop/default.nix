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
      nixpkgs = { inherit overlays; };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        sharedModules = [
          inputs.walker.homeManagerModules.default
          inputs.stylix.homeModules.stylix
          inputs.vicinae.homeManagerModules.default
        ];
        extraSpecialArgs = { inherit inputs overlays; };
        users.betongsuggan = import ./user-betongsuggan.nix;
      };
    }
  ];
}
