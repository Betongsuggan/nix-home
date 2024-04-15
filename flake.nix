{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { nixpkgs, ... }@inputs:
    let
      overlays = [ ];
    in
    rec {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop { inherit inputs overlays; };
      };

      homeConfigurations = {
        bits =
          nixosConfigurations.bits.config.home-manager.users.birgerrydback.home;
        private-laptop =
          nixosConfigurations.private-laptop.config.home-manager.users.betongsuggan.home;
      };
    };
}
