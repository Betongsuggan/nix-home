{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.development;
  aiProxyHost = inputs.self.lib.tailnet.fqdn "controller";
  ollamaBase = "http://${aiProxyHost}:11434";
in
{
  options.development = {
    enable = mkEnableOption "development tooling";

    python.enable = mkEnableOption "Python toolchain";
    node.enable = mkEnableOption "Node.js toolchain";
    go.enable = mkEnableOption "Go toolchain";
    kotlin.enable = mkEnableOption "Kotlin toolchain (installs JDK 25, Gradle 9, ktfmt, sets JAVA_HOME)";
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
        aider-chat
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
        jdk25
        gradle_9
        ktfmt
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
      {
        # Aider routes through controller's wake-proxy, which wakes the AI
        # host on demand. The ollama CLI isn't installed here — its `engine`
        # binary collides with mesa-demos pulled in by the games module.
        OLLAMA_API_BASE = ollamaBase;
      }
      // optionalAttrs cfg.node.enable {
        PATH = "$HOME/node_modules/bin:$PATH";
      }
      // optionalAttrs cfg.kotlin.enable {
        JAVA_HOME = "${pkgs.jdk25.home}";
      };
  };
}
