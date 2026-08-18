{ inputs, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    inputs.sops-nix.nixosModules.sops
    # lanzaboote is imported (but not enabled) because modules/secure-boot
    # references boot.lanzaboote — option must exist for the module set to
    # type-check even when secure-boot.enable = false.
    inputs.lanzaboote.nixosModules.lanzaboote
    ../../modules/common
    ../../modules/system.nix
    ./system.nix

    {
      nixpkgs = {
        inherit overlays;
        config = { allowUnfree = true; };
      };
    }
  ];
}
