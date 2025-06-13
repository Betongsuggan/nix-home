{ config, pkgs, lib, ... }:
with lib;

{
  options.development = {
    enable = mkEnableOption "Enable development toolings";
  };

  config = mkIf config.development.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        hello
        # Infrastructure
        unstable.nodePackages.aws-cdk
        localstack
        nodePackages.aws-cdk-local
        #pulumi
        #pulumiPackages.pulumi-language-go

        # Python
        python3

        # Kotlin
        kotlin
        openjdk17-bootstrap
        android-studio
        jetbrains.idea-community

        # Node stuff
        yarn
        nodePackages.pnpm
        nodejs_20

        # Haskell
        ghc
        cabal-install

        # Rust
        cargo
        rustc
        rustfmt
        gcc
        clippy

        # Go
        delve
        golangci-lint
        golangci-lint-langserver
        gotools
        gofumpt
        golines
        #nilaway

        # IaC
        terraform
        awscli2

        # Utilities
        altair
        docker-compose
        gnumake
        jq
        ls-lint
        newman
        silver-searcher
        #teleport
      ];
      programs.go.enable = true;

      home.sessionVariables = {
        JAVA_HOME = "${pkgs.openjdk17-bootstrap}";
        PATH = "$HOME/node_modules/bin:$PATH";
      };
    };
    unfreePackages = [ "terraform" "android-studio-stable" "idea-community" ];
  };
}
