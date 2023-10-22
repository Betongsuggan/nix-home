{
  description = "Betongsuggan's flake to rule them all. Proudly stolen from https://jdisaacs.com/blog/nixos-config/";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@inputs:
    let
      overlays = [ ];

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    in
    rec
    {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs overlays; };
      };
    };
}
