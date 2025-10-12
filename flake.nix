{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awscli-local.url = "github:Betongsuggan/awscli-local";
    walker.url = "github:abenz1267/walker";
  };

  outputs = { nixpkgs-unstable, awscli-local, ... }@inputs:
    let
      overlays = [
        (self: super: {
          awscli-local = awscli-local.packages.${self.system}.default;
          walker = inputs.walker.packages.${self.system}.default;
        })
        (final: prev: {
          unstable = import nixpkgs-unstable {
            system = prev.system;
            config.allowUnfree = true;
          };
        })
        (import ./overrides/aws-cdk.nix)
      ];

      mkHomeConfiguration = userModule:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            inherit overlays;
            config.allowUnfree = true;
          };

          modules = [
            userModule
            inputs.stylix.homeModules.stylix
            inputs.walker.homeManagerModules.default
          ];
          extraSpecialArgs = { inherit inputs overlays; };
        };
    in {
      nixosConfigurations = {
        bits = import ./hosts/bits/default.nix { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop/default.nix {
          inherit inputs overlays;
        };
        private-desktop = import ./hosts/private-desktop/default.nix {
          inherit inputs overlays;
        };
      };

      homeConfigurations = {
        "betongsuggan@private-desktop" =
          mkHomeConfiguration ./hosts/private-desktop/user-betongsuggan.nix;
        "gamer@private-desktop" =
          mkHomeConfiguration ./hosts/private-desktop/user-gamer.nix;
        "betongsuggan@private-laptop" =
          mkHomeConfiguration ./hosts/private-laptop/user-betongsuggan.nix;
        "birgerrydback@bits" =
          mkHomeConfiguration ./hosts/bits/user-birgerrydback.nix;
      };
    };
}
