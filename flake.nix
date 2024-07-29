{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    neovim.url = "github:Betongsuggan/nvim";
  };

  outputs = { nixpkgs, home-manager, neovim, ... }@inputs:
    let
      overlays = [ 
        (self: super: {
          neovim = neovim.packages.${self.system}.default;
        })
      ];
    in
    rec {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop { inherit inputs overlays; };
        private-desktop = import ./hosts/private-desktop { inherit inputs overlays; };
      };

      homeConfigurations = {
        private-laptop = nixosConfigurations.private-laptop.config.home-manager.users.betongsuggan.home;
        bits = nixosConfigurations.bits.config.home-manager.users.birgerrydback.home;
        #private-desktop =
        #  nixosConfigurations.private-desktop.config.home-manager.users.betongsuggan.home;
      };
    };
}
