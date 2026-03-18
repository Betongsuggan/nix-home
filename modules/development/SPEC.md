# Development

Installs a collection of development tools covering GitHub CLI, infrastructure/cloud tooling, AI tools, programming languages, and related utilities.

## Usage

```nix
development.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable development toolings |

## Notes

- Installed tools include: `gh`, `localstack`, `awscli2`, `aws-cdk`, `terraform`, `d2`, `claude-code`, `python3`, `yarn`, `pnpm`, `nodejs_20`, `delve`, `golangci-lint`, `gotools`, `gofumpt`, `golines`.
- Enables `programs.go`.
- Adds `$HOME/node_modules/bin` to `PATH`.
