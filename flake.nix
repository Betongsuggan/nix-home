{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    avante.url = "github:Betongsuggan/avante-nvim-flake/v0.0.8";
  };

  outputs = { nixpkgs, home-manager, avante, ... }@inputs:
    let
      overlays = [ 
        (self: super: {
          avante = avante.packages.${self.system}.default;
        })
      ];
    in
    rec {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop { inherit inputs overlays; };
      };

      homeConfigurations = {
        private-laptop = nixosConfigurations.private-laptop.config.home-manager.users.betongsuggan.home;
        bits = nixosConfigurations.bits.config.home-manager.users.birgerrydback.home;
      };
    };
}
