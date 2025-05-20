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
          --set NODE_PATH "$out/lib/node_modules/aws-cdk-local/node_modules:${prev.nodePackages.aws-cdk}/lib/node_modules:${prev.nodejs_20}/lib/node_modules"
                
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
