{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.development;
  # Tailnet-only HTTPS vhost on controller fronting the wake-proxy → Ollama
  # on home-desktop. See modules/ai-server/SPEC.md.
  ollamaBase = "https://llm.rydback.net";
in
{
  options.my.development = {
    enable = mkEnableOption "development tooling";

    infra.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Cloud tooling on PATH everywhere (LocalStack, AWS CLI/CDK, Terraform).
        Off when the repos bring these in their own dev shells (direnv)
      '';
    };

    python.enable = mkEnableOption "Python toolchain";
    node.enable = mkEnableOption "Node.js toolchain";
    go.enable = mkEnableOption "Go toolchain";
    kotlin.enable = mkEnableOption "Kotlin toolchain (installs the default JDK, Gradle 9, ktfmt, sets JAVA_HOME)";
    rust.enable = mkEnableOption "Rust toolchain";
    haskell.enable = mkEnableOption "Haskell toolchain";
  };

  config = mkIf cfg.enable {

    home.packages =
      with pkgs;
      [
        # Github
        gh
      ]
      ++ optionals cfg.infra.enable [
        localstack
        awscli-local
        aws-cdk-local # top-level attr from overrides/aws-cdk.nix (was nodePackages.*)
        aws-cdk
        unstable.awscli2
        terraform
      ]
      ++ [
        # AI tools (opencode is configured via programs.opencode below)
        unstable.claude-code
      ]
      ++ optionals cfg.python.enable [
        python3
      ]
      ++ optionals cfg.node.enable [
        nodejs_22 # nodejs_20 is EOL and marked insecure in 26.05
        yarn
        pnpm # was nodePackages.pnpm; nodePackages set removed in 26.05
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
        # nixpkgs' default JDK, the one kotlin and gradle run on. ktfmt is
        # wrapped with jre_headless upstream, which would be a second JDK
        # (565 MiB) in the closure; run it on the same one
        jdk
        gradle_9
        (ktfmt.override { jre_headless = jdk; })
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

    # Agentic coding CLI against the local models (aider is unmaintained
    # since 2025). The provider is Ollama's OpenAI-compatible endpoint behind
    # llm.rydback.net (HTTPS, tailnet-only), so the first request wakes the
    # AI host via controller's wake-proxy. opencode needs each model listed
    # by name; keep this in step with `my.ai-server.models` on desktop.
    # The ollama CLI itself isn't installed here — its `engine` binary
    # collides with mesa-demos pulled in by the games module.
    programs.opencode = {
      enable = true;
      package = pkgs.unstable.opencode;
      settings = {
        model = "ollama/qwen2.5-coder:14b";
        provider.ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (${ollamaBase})";
          options.baseURL = "${ollamaBase}/v1";
          models = {
            "qwen2.5-coder:14b".name = "Qwen2.5 Coder 14B";
            "gpt-oss:20b".name = "gpt-oss 20B";
          };
        };
      };
    };

    home.sessionVariables =
      optionalAttrs cfg.node.enable {
        PATH = "$HOME/node_modules/bin:$PATH";
      }
      // optionalAttrs cfg.kotlin.enable {
        JAVA_HOME = "${pkgs.jdk.home}";
      };
  };
}
