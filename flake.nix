{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awscli-local.url = "github:Betongsuggan/awscli-local";
    audiomenu.url = "github:Betongsuggan/audiomenu";
    monitormenu.url = "github:Betongsuggan/monitormenu";
    walker.url = "github:abenz1267/walker/v2.11.2";
    elephant.url = "github:abenz1267/elephant/v2.16.1";
    vicinae.url = "path:/home/birgerrydback/Development/vicinae-fork";
    vicinae.inputs.nixpkgs.follows = "nixpkgs";
    vicinae-extensions-fork.url = "path:/home/birgerrydback/Development/vicinae-extensions-fork";
    vicinae-extensions-fork.inputs.nixpkgs.follows = "nixpkgs";

    # Override walker's elephant input to use our pinned version
    walker.inputs.elephant.follows = "elephant";
    console-mode.url = "github:Betongsuggan/console-mode";
    d2.url = "github:Betongsuggan/terrastruct-d2-nix";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs-unstable, awscli-local, nur, ... }@inputs:
    let
      overlays = [
        nur.overlays.default
        (self: super: {
          awscli-local = awscli-local.packages.${self.system}.default;
          walker = inputs.walker.packages.${self.system}.default;
          elephant = inputs.elephant.packages.${self.system}.default;
          audiomenu = inputs.audiomenu.packages.${self.system}.default;
          monitormenu = inputs.monitormenu.packages.${self.system}.default;
          console-mode = inputs.console-mode.packages.${self.system}.default;
          d2 = inputs.d2.packages.${self.system}.default;
          vicinae = inputs.vicinae.packages.${self.system}.default;

          # Custom-built Vicinae extensions with React bundled
          vicinaeExtensions = self.callPackage ./pkgs/vicinae-extensions.nix { inherit inputs; };
          vicinae-wifi-commander = self.vicinaeExtensions.wifi-commander;
          vicinae-bluetooth = self.vicinaeExtensions.bluetooth;
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
            inputs.walker.homeManagerModules.default
            inputs.vicinae.homeManagerModules.default
            inputs.stylix.homeModules.stylix
            inputs.console-mode.homeManagerModules.default
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
