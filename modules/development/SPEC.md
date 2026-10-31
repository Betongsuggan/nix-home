# Development

Installs a baseline of development tooling (GitHub CLI, infrastructure/cloud, AI tools) and lets each host opt into the language toolchains it needs. Each language sub-option installs its packages and wires up any required environment (e.g. Kotlin sets `JAVA_HOME`).

## Usage

```nix
my.development = {
  enable = true;
  python.enable = true;
  node.enable = true;
  go.enable = true;
  kotlin.enable = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the development module (installs baseline tooling) |
| infra.enable | bool | true | LocalStack, awscli-local, AWS CDK (+ cdklocal), awscli2 and Terraform on `PATH` everywhere; off when repos bring them in their dev shells |
| python.enable | bool | false | Install Python toolchain |
| node.enable | bool | false | Install Node.js toolchain and add `$HOME/node_modules/bin` to `PATH` |
| go.enable | bool | false | Install Go toolchain and enable `programs.go` |
| kotlin.enable | bool | false | Install Kotlin toolchain (the default JDK, Gradle 9, ktfmt) and set `JAVA_HOME` |
| rust.enable | bool | false | Install Rust toolchain |
| haskell.enable | bool | false | Install Haskell toolchain |

## Notes

- Baseline (installed whenever `enable = true`): `gh`, `localstack`, `awscli-local`, `aws-cdk-local`, `aws-cdk`, `awscli2`, `terraform` (these five under `infra.enable`), `claude-code`, `opencode`. `d2` (it pulled in Playwright's three browsers, 0.9 GiB) and `android-tools` were dropped on 2026-10-31; use `nix run nixpkgs#d2` / `nix shell nixpkgs#android-tools` when needed.
- **opencode** (`programs.opencode`, from unstable) replaces aider, which has had no release since 2025. Its `opencode.json` declares one provider, `ollama`, pointing at `https://llm.rydback.net/v1` (the tailnet-only HTTPS vhost on controller that fronts the wake-proxy and wakes the AI host on demand), with `qwen2.5-coder:14b` as default model and `gpt-oss:20b` as the alternative. opencode needs each model listed by name, so keep that list in step with `my.ai-server.models` on desktop. The `ollama` CLI is intentionally not installed — its `engine` binary collides with `mesa-demos` pulled in by the `games` module.
- Per language:
  - **python**: `python3`.
  - **node**: `nodejs_20`, `yarn`, `pnpm`. Adds `$HOME/node_modules/bin` to `PATH`.
  - **go**: `delve`, `golangci-lint`, `golangci-lint-langserver`, `gotools`, `gofumpt`, `golines`. Enables `programs.go`.
  - **kotlin**: `kotlin`, `jdk` (nixpkgs' default, the one kotlin and gradle run on), `gradle_9`, `ktfmt` overridden to run on that same `jdk` instead of its upstream `jre_headless`, so the closure holds one JDK, not two. Sets `JAVA_HOME` to that JDK. Gradle 9 on `PATH` is for ad-hoc use; project builds still go through the Gradle wrapper, which can be pointed at the Nix JDK via `org.gradle.java.installations.paths` in `~/.gradle/gradle.properties`.
  - **rust**: `cargo`, `rustc`, `rustfmt`, `clippy`, `gcc`.
  - **haskell**: `ghc`, `cabal-install`.
