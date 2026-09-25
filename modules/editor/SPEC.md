# Editor

Installs Neovim from the `nvim` flake input (the nixvim configuration in `github:Betongsuggan/nvim`), built for this user: the languages they develop in, the desktop's colors, and nixd completion for this host's own NixOS and Home Manager options. Provides `nvim`, `vim` and `vi`.

## Usage

```nix
# Nothing to set in most cases: enabled with my.shell, languages follow my.development
my.editor = {
  languages.rust = true;   # e.g. Rust support without a global Rust toolchain
  flakePath = null;        # no NixOS/HM option completion (no checkout on this machine)
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | `my.shell.enable` | Install the editor |
| languages.nix | bool | user is an admin (`my.common.admins`) | nixd (with this host's NixOS/HM options), nixfmt |
| languages.go | bool | `my.development.go.enable` | gopls, golines/gofumpt, delve, neotest-golang |
| languages.rust | bool | `my.development.rust.enable` | rustaceanvim (rust-analyzer), crates.nvim, lldb-dap |
| languages.typescript | bool | `my.development.node.enable` | vtsls, neotest-jest |
| languages.kotlin | bool | `my.development.kotlin.enable` | kotlin-lsp, ktfmt, neotest-gradle (x86_64 only) |
| flakePath | nullOr str | `~/nix-home` | Checkout nixd evaluates for option completion; null disables it |

## Notes

- Always included: Lua formatting, Markdown rendering, highlighting for Nix and bash/JSON/YAML/TOML (the core is ~330 MiB). Nix support (nixd) is for the admin accounts, who edit this repo; e.g. gamer gets only the core. Each extra language adds its whole toolchain integration; compilers and build tools are never bundled (they come from `my.development` or the project's devShell).
- Colors: the Neovim colorscheme of `my.theming.scheme` (gruvbox.nvim, kanagawa.nvim), so the editor matches the desktop with the scheme's own hand-tuned highlighting; catppuccin when theming is off.
- With Nix enabled, nixd gets `nixosConfigurations.<host>.options` and the Home Manager user options from `flakePath` (evaluated by nixd on demand, as the user, so the checkout must be able to fetch its inputs, e.g. nix-vault over the tailnet).
- Update the editor with `nix flake update nvim`. Its own options (`languages.*`, `theme.base16`, `languages.nix.server`) are documented in the nvim repository's README.
