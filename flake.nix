{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Kernel pin for island-stationary. Its keyboard and mouse receivers sit in
    # the monitor's USB hub, which reaches the machine only through the RTX
    # 2070's USB-C (VirtualLink) port. Zen 7.1.x intermittently drops the
    # Logitech receiver behind that hub (7 disconnects in ~40min, vs zero over
    # 2.5 months on 7.0.9), and also fails to init the GPU's Cypress Type-C
    # controller: "ucsi_ccg 0-0008: error -ETIMEDOUT: PPM init failed". This rev
    # is the last one that ran the host cleanly. Re-test on zen 7.2 and drop
    # this input if the receiver stays connected.
    nixpkgs-kernel.url = "github:NixOS/nixpkgs/687f05a9184cad4eaf905c48b63649e3a86f5433";

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
    # and niri keep their own pins so their Cachix caches keep hitting.
    awscli-local = {
      url = "github:Betongsuggan/awscli-local";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    audiomenu = {
      url = "github:Betongsuggan/audiomenu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    monitormenu = {
      url = "github:Betongsuggan/monitormenu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant.url = "github:abenz1267/elephant/v2.16.1";

    walker = {
      url = "github:abenz1267/walker/v2.11.2";
      inputs.elephant.follows = "elephant";
    };

    # Upstream extensions, pinned: later revisions add a native npm module
    # (usocket) to the bluetooth extension whose node-gyp build fails
    vicinae-extensions = {
      url = "github:vicinaehq/extensions/b698ce7ecb58dec1efe297f87370253d8f6ba9d5";
      flake = false;
    };

    # The editor (nixvim, on the same NixOS release as the fleet)
    nvim = {
      url = "github:Betongsuggan/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    console-mode = {
      url = "github:Betongsuggan/console-mode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming NixOS modules (Steam platform optimizations, low-latency
    # PipeWire) and wine-tkg. Keeps its own nixpkgs so its Cachix cache hits
    nix-gaming.url = "github:fufexan/nix-gaming";

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
    # headscale tailnet (`my.home-network`, mode `onboarded`) before it can fetch this.
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
      # One check per host (its system toplevel, grouped by the host's own
      # platform) plus, on x86_64, one per unused backend/module
      # (checks/backends.nix). `nix flake check --no-build --all-systems`
      # evaluates them all without building.
      checks =
        nixpkgs.lib.recursiveUpdate
          (nixpkgs.lib.foldlAttrs (
            acc: name: host:
            nixpkgs.lib.recursiveUpdate acc {
              ${host.pkgs.stdenv.hostPlatform.system}.${name} = host.config.system.build.toplevel;
            }
          ) { } inputs.self.nixosConfigurations)
          {
            x86_64-linux = import ./checks/backends.nix {
              inherit (inputs) self;
              inherit (nixpkgs) lib;
            };
          };

      nixosConfigurations = nixpkgs.lib.mapAttrs (import ./lib/mk-host.nix {
        inherit inputs overlays;
      }) selfLib.hosts;

      packages.x86_64-linux.terraform-mail = inputs.terranix.lib.terranixConfiguration {
        system = "x86_64-linux";
        modules = [ ./hosts/mail/terraform.nix ];
        extraArgs = { inherit inputs; };
      };

      # Bootable SD-card image for island-pi with the host config baked in.
      # Built on any x86 host via binfmt (see modules/common/nixos.nix); the full
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
