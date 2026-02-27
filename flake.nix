{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awscli-local.url = "github:Betongsuggan/awscli-local";
    audiomenu.url = "github:Betongsuggan/audiomenu";
    monitormenu.url = "github:Betongsuggan/monitormenu";
    elephant.url = "github:abenz1267/elephant/v2.16.1";

    walker = {
      url = "github:abenz1267/walker/v2.11.2";
      inputs.elephant.follows = "elephant";
    };

    vicinae = {
      url = "github:Betongsuggan/vicinae-fork";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url =
        "github:Betongsuggan/vicinae-extensions/add-hyprland-monitor-extension";
      flake = false;
    };

    console-mode.url = "github:Betongsuggan/console-mode";
    d2.url = "github:Betongsuggan/terrastruct-d2-nix";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { nixpkgs-unstable, awscli-local, nur, ... }@inputs:
    let
      overlays = [
        nur.overlays.default
        (self: super:
          let
            mkVicinaeExtension =
              inputs.vicinae.packages.${self.system}.mkVicinaeExtension;
          in {
            awscli-local = awscli-local.packages.${self.system}.default;
            walker = inputs.walker.packages.${self.system}.default;
            elephant = inputs.elephant.packages.${self.system}.default;
            audiomenu = inputs.audiomenu.packages.${self.system}.default;
            monitormenu = inputs.monitormenu.packages.${self.system}.default;
            console-mode = inputs.console-mode.packages.${self.system}.default;
            d2 = inputs.d2.packages.${self.system}.default;
            vicinae = inputs.vicinae.packages.${self.system}.default;

            # Vicinae extensions
            vicinae-wifi-commander = mkVicinaeExtension {
              pname = "wifi-commander";
              src = "${inputs.vicinae-extensions}/extensions/wifi-commander";
            };
            vicinae-bluetooth = mkVicinaeExtension {
              pname = "bluetooth";
              src = "${inputs.vicinae-extensions}/extensions/bluetooth";
            };
            vicinae-monitor = mkVicinaeExtension {
              pname = "hyprland-monitors";
              src = "${inputs.vicinae-extensions}/extensions/hyprland-monitors";
            };
          })
        (final: prev: {
          unstable = import nixpkgs-unstable {
            system = prev.system;
            config.allowUnfree = true;
          };
        })
        (import ./overrides/aws-cdk.nix)
        (import ./overrides/niri.nix { inherit inputs; })
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
            inputs.niri.homeModules.niri
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
