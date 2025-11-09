{ config, pkgs, lib, ... }:
with lib;

{
  options.development = {
    enable = mkEnableOption "Enable development toolings";
  };

  config = mkIf config.development.enable {

    home.packages = with pkgs; [

      # Infrastructure
      localstack
      awscli-local
      nodePackages.aws-cdk-local
      unstable.nodePackages.aws-cdk
      awscli2
      terraform
      d2

      # AI tools
      unstable.claude-code

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

      # Utilities
      altair
      docker-compose
      gnumake
      jq
      ls-lint
      newman
      silver-searcher
      openssl
    ];
    programs.go.enable = true;

    home.sessionVariables = {
      JAVA_HOME = "${pkgs.openjdk17-bootstrap}";
      PATH = "$HOME/node_modules/bin:$PATH";
    };
    # unfreePackages moved to system level configuration
  };
}
