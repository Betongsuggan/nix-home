{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.development;
in
{
  options.development = {
    enable = mkEnableOption "development tooling";

    python.enable = mkEnableOption "Python toolchain";
    node.enable = mkEnableOption "Node.js toolchain";
    go.enable = mkEnableOption "Go toolchain";
    kotlin.enable = mkEnableOption "Kotlin toolchain (installs JDK 21, sets JAVA_HOME)";
    rust.enable = mkEnableOption "Rust toolchain";
    haskell.enable = mkEnableOption "Haskell toolchain";
  };

  config = mkIf cfg.enable {

    home.packages =
      with pkgs;
      [
        unstable.android-tools
        # Github
        gh

        # Infrastructure
        localstack
        awscli-local
        nodePackages.aws-cdk-local
        aws-cdk
        unstable.awscli2
        terraform
        d2

        # AI tools
        unstable.claude-code
      ]
      ++ optionals cfg.python.enable [
        python3
      ]
      ++ optionals cfg.node.enable [
        nodejs_20
        yarn
        nodePackages.pnpm
      ]
      ++ optionals cfg.go.enable [
        delve
        unstable.golangci-lint
        unstable.golangci-lint-langserver
        gotools
        gofumpt
        golines
      ]
      ++ optionals cfg.kotlin.enable [
        kotlin
        jdk21
      ]
      ++ optionals cfg.rust.enable [
        cargo
        rustc
        rustfmt
        clippy
        gcc
      ]
      ++ optionals cfg.haskell.enable [
        ghc
        cabal-install
      ];

    programs.go.enable = cfg.go.enable;

    home.sessionVariables =
      optionalAttrs cfg.node.enable {
        PATH = "$HOME/node_modules/bin:$PATH";
      }
      // optionalAttrs cfg.kotlin.enable {
        JAVA_HOME = "${pkgs.jdk21.home}";
      };
  };
}
