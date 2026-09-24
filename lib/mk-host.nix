# Builds one nixosConfiguration from hosts/<name>/ by convention:
#
#   system.nix        host-wide NixOS config (required)
#   user-<user>.nix   one Home Manager user each (optional; any number)
#
# Everything shared by the fleet lives here once: the module aggregators,
# overlays, unfree policy and the Home Manager wiring. `host` is the host's
# entry in lib.hosts, which provides `system` and `hostName`.
{ inputs, overlays }:
name: host:
let
  inherit (inputs.nixpkgs) lib;

  dir = ../hosts + "/${name}";

  homeUsers =
    lib.mapAttrs'
      (
        file: _:
        lib.nameValuePair (lib.removeSuffix ".nix" (lib.removePrefix "user-" file)) (dir + "/${file}")
      )
      (
        lib.filterAttrs (
          file: type: type == "regular" && lib.hasPrefix "user-" file && lib.hasSuffix ".nix" file
        ) (builtins.readDir dir)
      );
in
lib.nixosSystem {
  inherit (host) system;
  specialArgs = { inherit inputs; };
  modules = [
    ../modules/nixos.nix
    (dir + "/system.nix")
    {
      networking.hostName = host.hostName;
      nixpkgs = {
        inherit overlays;
        config.allowUnfree = true;
      };
    }
  ]
  ++ lib.optionals (homeUsers != { }) [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = { inherit inputs; };
        sharedModules = [ ../modules/home.nix ];
        users = homeUsers;
      };
    }
  ];
}
