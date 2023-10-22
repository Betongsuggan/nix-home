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
      globals =
        let baseName = "birgerrydback";
        in
        {
          user = "birgerrydback";
          fullName = "Birger Rydback";
          #gitName = "Birger Rydback";
          #gitEmail = "birger.rydback@bits.bi";
          #hostnames = {
          #  git = "git.${baseName}";
          #  metrics = "metrics.${baseName}";
          #  prometheus = "prom.${baseName}";
          #  secrets = "vault.${baseName}";
          #  stream = "stream.${baseName}";
          #  content = "cloud.${baseName}";
          #  books = "books.${baseName}";
          #  download = "download.${baseName}";
          #};
        };

      overlays = [ ];

      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" ];
    in
    rec
    {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs globals overlays; };
      };
    };
}
