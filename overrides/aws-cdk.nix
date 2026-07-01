(final: prev: {
  # Custom aws-cdk built from npm to get the latest version.
  # nodejs_22: nodejs_20 was EOL'd and marked insecure in nixpkgs 26.05.
  aws-cdk = prev.stdenv.mkDerivation rec {
    pname = "aws-cdk";
    version = "2.1033.0";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/aws-cdk/-/aws-cdk-${version}.tgz";
      hash = "sha256-lfEnTSHYWNlVgtCjzq6rmHE75GLqvmU94cZhf8nTxJ4=";
    };

    nativeBuildInputs = [ prev.nodejs_22 prev.makeWrapper ];

    unpackPhase = ''
      mkdir -p source
      tar -xzf $src -C source --strip-components=1
    '';

    installPhase = ''
      mkdir -p $out/lib/node_modules/aws-cdk
      cp -r source/* $out/lib/node_modules/aws-cdk/

      mkdir -p $out/bin
      makeWrapper ${prev.nodejs_22}/bin/node $out/bin/cdk \
        --add-flags "$out/lib/node_modules/aws-cdk/bin/cdk" \
        --set NODE_PATH "$out/lib/node_modules"
    '';

    meta = {
      description = "AWS Cloud Development Kit CLI";
      homepage = "https://github.com/aws/aws-cdk";
      license = prev.lib.licenses.asl20;
    };
  };

  # cdklocal wrapper. Formerly attached under `nodePackages.aws-cdk-local`, but
  # the `nodePackages` set was removed in nixpkgs 26.05, so it's now a plain
  # top-level attribute (referenced as `aws-cdk-local` in the development module).
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

    nativeBuildInputs = [ prev.nodejs_22 prev.makeWrapper ];

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
      makeWrapper ${prev.nodejs_22}/bin/node $out/bin/cdklocal \
        --add-flags "$out/lib/node_modules/aws-cdk-local/bin/cdklocal" \
        --set NODE_PATH "$out/lib/node_modules/aws-cdk-local/node_modules:${final.aws-cdk}/lib/node_modules:${prev.nodejs_22}/lib/node_modules"

      chmod +x $out/bin/cdklocal
    '';

    meta = {
      description = "Run your AWS CDK applications with LocalStack";
      homepage = "https://github.com/localstack/aws-cdk-local";
      license = prev.lib.licenses.asl20;
    };
  };
})
