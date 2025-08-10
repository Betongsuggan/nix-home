{ inputs, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.homeModules.stylix
    ../../modules/common
    ../../modules/system
    ./system.nix
    {
      nixpkgs = { inherit overlays; };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs overlays; };
        users.betongsuggan = import ./user-betongsuggan.nix;
        users.gamer = import ./user-gamer.nix;
      };
    }
  ];
}
