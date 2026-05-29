# Development

Installs a baseline of development tooling (GitHub CLI, infrastructure/cloud, AI tools) and lets each host opt into the language toolchains it needs. Each language sub-option installs its packages and wires up any required environment (e.g. Kotlin sets `JAVA_HOME`).

## Usage

```nix
development = {
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
| python.enable | bool | false | Install Python toolchain |
| node.enable | bool | false | Install Node.js toolchain and add `$HOME/node_modules/bin` to `PATH` |
| go.enable | bool | false | Install Go toolchain and enable `programs.go` |
| kotlin.enable | bool | false | Install Kotlin toolchain (with JDK 21) and set `JAVA_HOME` |
| rust.enable | bool | false | Install Rust toolchain |
| haskell.enable | bool | false | Install Haskell toolchain |

## Notes

- Baseline (installed whenever `enable = true`): `gh`, `localstack`, `awscli-local`, `aws-cdk-local`, `aws-cdk`, `awscli2`, `terraform`, `d2`, `claude-code`.
- Per language:
  - **python**: `python3`.
  - **node**: `nodejs_20`, `yarn`, `pnpm`. Adds `$HOME/node_modules/bin` to `PATH`.
  - **go**: `delve`, `golangci-lint`, `golangci-lint-langserver`, `gotools`, `gofumpt`, `golines`. Enables `programs.go`.
  - **kotlin**: `kotlin`, `jdk21`. Sets `JAVA_HOME` to the JDK 21 store path.
  - **rust**: `cargo`, `rustc`, `rustfmt`, `clippy`, `gcc`.
  - **haskell**: `ghc`, `cabal-install`.
