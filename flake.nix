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
      url = "github:Betongsuggan/vicinae-extensions/add-hyprland-monitor-extension";
      flake = false;
    };

    console-mode.url = "github:Betongsuggan/console-mode";
    d2.url = "github:Betongsuggan/terrastruct-d2-nix";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.niri-stable.url = "github:YaLTeR/niri/v26.04";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-vault.git is served by controller's git-server module, reached via
    # the tailnet (no public SSH exposure). Each consuming host must be on the
    # headscale tailnet (`tailscale-client` block) before it can fetch this.
    # Bootstrap an installer via `--override-input nix-vault path:...` if the
    # host hasn't joined the tailnet yet.
    nix-vault.url = "git+ssh://git@controller/var/lib/git/nix-vault.git?ref=main";
    #nix-vault.url = "git+ssh://git@controller.ts.rydback.net/var/lib/git/nix-vault.git?ref=main";
    # once you want hosts/installers to fetch over SSH instead of relying on a
    # local clone. Bootstrap an installer via `--override-input nix-vault path:...`
    # if the host's SSH key isn't yet authorized on controller.
    #nix-vault.url = "path:/home/birgerrydback/nix-vault";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      awscli-local,
      nur,
      ...
    }@inputs:
    let
      selfLib = import ./lib { inherit (nixpkgs) lib; };

      overlays = [
        nur.overlays.default
        (
          self: super:
          let
            mkVicinaeExtension =
              inputs.vicinae.packages.${self.stdenv.hostPlatform.system}.mkVicinaeExtension;
          in
          {
            awscli-local = awscli-local.packages.${self.stdenv.hostPlatform.system}.default;
            walker = inputs.walker.packages.${self.stdenv.hostPlatform.system}.default;
            elephant = inputs.elephant.packages.${self.stdenv.hostPlatform.system}.default;
            audiomenu =
              inputs.audiomenu.packages.${self.stdenv.hostPlatform.system}.default;
            monitormenu =
              inputs.monitormenu.packages.${self.stdenv.hostPlatform.system}.default;
            console-mode =
              inputs.console-mode.packages.${self.stdenv.hostPlatform.system}.default;
            d2 = inputs.d2.packages.${self.stdenv.hostPlatform.system}.default;
            vicinae = inputs.vicinae.packages.${self.stdenv.hostPlatform.system}.default;

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
          }
        )
        (final: prev: {
          unstable = import nixpkgs-unstable {
            system = prev.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          };
        })
        (import ./overrides/aws-cdk.nix)
        (import ./overrides/niri.nix { inherit inputs; })
      ];

      mkHomeConfiguration =
        userModule:
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
    in
    {
      lib = selfLib;

      nixosConfigurations = {
        bits = import ./hosts/bits/default.nix { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop/default.nix {
          inherit inputs overlays;
        };
        desktop = import ./hosts/desktop/default.nix {
          inherit inputs overlays;
        };
        island-stationary = import ./hosts/island-stationary/default.nix {
          inherit inputs overlays;
        };
        controller = import ./hosts/controller/default.nix {
          inherit inputs overlays;
        };
        mail = import ./hosts/mail/default.nix {
          inherit inputs overlays;
        };
      };

      packages.x86_64-linux.terraform-mail =
        inputs.terranix.lib.terranixConfiguration
          {
            system = "x86_64-linux";
            modules = [ ./hosts/mail/terraform.nix ];
            extraArgs = { inherit inputs; };
          };

      homeConfigurations = {
        "betongsuggan@desktop" =
          mkHomeConfiguration ./hosts/desktop/user-betongsuggan.nix;
        "gamer@desktop" =
          mkHomeConfiguration ./hosts/desktop/user-gamer.nix;
        "betongsuggan@private-laptop" =
          mkHomeConfiguration ./hosts/private-laptop/user-betongsuggan.nix;
        "birgerrydback@bits" = mkHomeConfiguration ./hosts/bits/user-birgerrydback.nix;
        "betongsuggan@island-stationary" =
          mkHomeConfiguration ./hosts/island-stationary/user-betongsuggan.nix;
        "gamer@island-stationary" =
          mkHomeConfiguration ./hosts/island-stationary/user-gamer.nix;
        "betongsuggan@controller" =
          mkHomeConfiguration ./hosts/controller/user-betongsuggan.nix;
      };
    };
}
