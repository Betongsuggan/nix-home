{
  description = "Betongsuggan's flake to rule them all";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";
    neovim.url = "github:Betongsuggan/nvim";
    wofi-bluetooth.url = "github:Betongsuggan/wofi-bluetooth";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, neovim, wofi-bluetooth, ... }@inputs:
    let
      overlays = [
        (self: super: {
          neovim = neovim.packages.${self.system}.default;
          wofi-bluetooth = wofi-bluetooth.packages.${self.system}.default;
          walker-module = inputs.walker.homeManagerModules.default;
        })
        (final: prev: {
          unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        })
        (final: prev: {
          nodePackages = prev.nodePackages // {

            aws-cdk-local = prev.stdenv.mkDerivation rec {
              pname = "aws-cdk-local";
              version = "2.0.11";

              src = prev.fetchFromGitHub {
                owner = "localstack";
                repo = "aws-cdk-local";
                rev = "9bb17186e0201a93d84edd0e8478f7da69ae5414";
                sha256 = "sha256-1cgcBXe2N8sSNWe2L0QO8/MiBpAWKGz5DBxtl5s3+Lw=";
              };

              # Fetch the diff package
              diffPkg = prev.fetchurl {
                url = "https://registry.npmjs.org/diff/-/diff-5.1.0.tgz";
                sha256 = "sha256-Eq/4dNcQH4h4dSKlZ4HzgkD+ZopUXvAtO8X6UCvaak8=";
              };

              nativeBuildInputs = [
                prev.nodejs_20
                prev.makeWrapper
              ];

              buildPhase = ''
                # Create a package directory
                mkdir -p $out/lib/node_modules/aws-cdk-local
                cp -r $src/* $out/lib/node_modules/aws-cdk-local/
                
                # Create node_modules directory
                mkdir -p $out/lib/node_modules/aws-cdk-local/node_modules/diff
                
                # Extract the diff package
                tar -xzf ${diffPkg} -C $out/lib/node_modules/aws-cdk-local/node_modules/diff --strip-components=1
              '';

              installPhase = ''
                mkdir -p $out/bin
                
                # Create the cdklocal executable with proper NODE_PATH
                makeWrapper ${prev.nodejs_20}/bin/node $out/bin/cdklocal \
                  --add-flags "$out/lib/node_modules/aws-cdk-local/bin/cdklocal" \
                  --set NODE_PATH "$out/lib/node_modules/aws-cdk-local/node_modules:${prev.unstable.nodePackages.aws-cdk}/lib/node_modules:${prev.nodejs_20}/lib/node_modules"
                
                chmod +x $out/bin/cdklocal
              '';

              meta = {
                description = "Run your AWS CDK applications with LocalStack";
                homepage = "https://github.com/localstack/aws-cdk-local";
                license = prev.lib.licenses.asl20;
              };
            };
          };
        })
      ];
    in
    rec {
      nixosConfigurations = {
        bits = import ./hosts/bits { inherit inputs overlays; };
        private-laptop = import ./hosts/private-laptop { inherit inputs overlays; };
        private-desktop = import ./hosts/private-desktop { inherit inputs overlays; };
      };

      homeConfigurations = {
        private-laptop = nixosConfigurations.private-laptop.config.home-manager.users.betongsuggan.home;
        bits = nixosConfigurations.bits.config.home-manager.users.birgerrydback.home;
        #private-desktop =
        #  nixosConfigurations.private-desktop.config.home-manager.users.betongsuggan.home;
      };
    };
}
