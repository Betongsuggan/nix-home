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

    neovim.url = "github:Betongsuggan/nvim";
    awscli-local.url = "github:Betongsuggan/awscli-local";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, neovim, stylix, awscli-local, ... }@inputs:
    let
      overlays = [
        (self: super: {
          neovim = neovim.packages.${self.system}.default;
          awscli-local = awscli-local.packages.${self.system}.default;
          walker-module = inputs.walker.homeManagerModules.default;
        })
        (final: prev: {
          unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        })
        (import ./overrides/aws-cdk.nix)
      ];
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };

      # ✅ Fake package here
      mockPackage = pkgs.runCommand "fake-package" { } ''
        mkdir -p $out
        echo `{ "time": "2020-04-26T13:32:17+00:00", "condition" = true, "message" = "fuck this" }` > $out/fake.txt
      '';
    in
    rec {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop { inherit inputs overlays; };
        private-desktop = import ./hosts/private-desktop { inherit inputs overlays; };
      };

      homeConfigurations = {
        #private-laptop = nixosConfigurations.private-laptop.config.home-manager.users.betongsuggan.home;
        #bits = nixosConfigurations.bits.config.home-manager.users.birgerrydback.home;
        private-desktop = nixosConfigurations.private-desktop.config.home-manager.users.betongsuggan.home // {
          config = {
            news = {
              display = "silent";
              json.output = mockPackage;
              entries = [ ];
            };
          };
        };
      };
    };
}
