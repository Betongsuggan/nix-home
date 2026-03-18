# Direnv

Enables direnv for automatic per-directory environment management with nix-direnv integration for cached Nix shells.

## Usage

```nix
direnv.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable direnv for per-directory environment management |

## Notes

- Enables `nix-direnv` for better Nix integration with environment caching.
- Hides environment diffs in shell output (`hide_env_diff = true`).
- Suppresses direnv log output by setting `DIRENV_LOG_FORMAT` to empty.
