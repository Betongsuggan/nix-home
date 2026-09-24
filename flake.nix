{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # onlyoffice-documentserver 9.3.1 fails to link on current nixos-26.05: its
    # bundled V8 references `icu_78::UnicodeSet` symbols the linked ICU doesn't
    # provide, so the local from-source build dies in ld. Hydra last built this
    # package green (and cached) at the rev below, so pinning the whole package
    # + its own closure here makes it *substitute* instead of compiling. Drop
    # this input + its overlay once 26.05 ships a working onlyoffice build.
    nixpkgs-onlyoffice.url = "github:NixOS/nixpkgs/e8210c649915deed7080033cdbabcc19e40bb899";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Own flakes and NUR build against the fleet's nixpkgs. walker/elephant
    # and niri keep their own pins so their Cachix caches keep hitting;
    # audiomenu/monitormenu keep theirs because their locked rust-overlay
    # toolchains don't unpack on nixpkgs 26.05 (bump rust-overlay upstream first).
    awscli-local = {
      url = "github:Betongsuggan/awscli-local";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

    console-mode = {
      url = "github:Betongsuggan/console-mode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    d2 = {
      url = "github:Betongsuggan/terrastruct-d2-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    nix-vault.url = "git+ssh://git@controller.ts.rydback.net/var/lib/git/nix-vault.git?ref=main";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      selfLib = import ./lib { inherit (nixpkgs) lib; };

      overlays = import ./overlays inputs;
    in
    {
      lib = selfLib;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;

      # One check per host: its system toplevel, grouped by the host's own
      # platform. `nix flake check --no-build --all-systems` evaluates every host
      # without building; drop `--no-build` to build them.
      checks = nixpkgs.lib.foldlAttrs (
        acc: name: host:
        nixpkgs.lib.recursiveUpdate acc {
          ${host.pkgs.stdenv.hostPlatform.system}.${name} = host.config.system.build.toplevel;
        }
      ) { } inputs.self.nixosConfigurations;

      nixosConfigurations = nixpkgs.lib.mapAttrs (import ./lib/mk-host.nix {
        inherit inputs overlays;
      }) selfLib.hosts;

      packages.x86_64-linux.terraform-mail = inputs.terranix.lib.terranixConfiguration {
        system = "x86_64-linux";
        modules = [ ./hosts/mail/terraform.nix ];
        extraArgs = { inherit inputs; };
      };

      # Bootable SD-card image for island-pi with the host config baked in.
      # Built on any x86 host via binfmt (see modules/common); the full
      # attribute path is required since `nix build .#<name>` only searches
      # the invoking system's packages:
      #   nix build .#packages.aarch64-linux.island-pi-sd-image
      # The sd-image module only augments the image build (partitioning,
      # all-hardware initrd); deployed generations come from nixosConfigurations
      # .island-pi unchanged.
      packages.aarch64-linux.island-pi-sd-image =
        (inputs.self.nixosConfigurations.island-pi.extendModules {
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ];
        }).config.system.build.sdImage;
    };
}
