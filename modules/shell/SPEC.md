# Shell

Configures shell environments with support for bash, fish, and nushell backends. Provides shared aliases, editor settings, vi mode, and extra PATH entries that apply across all shell backends.

## Usage

```nix
shell = {
  enable = true;
  backend = "fish";
  aliases = {
    ll = "ls -la --color=auto";
    vim = "nix run github:/Betongsuggan/nvim --refresh";
  };
  viMode = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable shell configuration |
| backend | enum ["bash" "fish" "nushell"] | "bash" | Shell backend to use |
| aliases | attrsOf str | (see default.nix) | Shell aliases shared across all shells |
| editor | str | "nix run github:/Betongsuggan/nvim" | Default editor |
| viMode | bool | true | Enable vi mode in shells |
| extraPaths | listOf str | ["~/.cargo/bin/"] | Extra paths to add to PATH |
| bash.enable | bool | (true if backend == "bash") | Enable bash shell |
| bash.extraInit | lines | "" | Extra bash initialization commands |
| fish.enable | bool | (true if backend == "fish") | Enable fish shell |
| fish.enableNixIndex | bool | true | Enable nix-index integration for fish |
| fish.extraInit | lines | "" | Extra fish initialization commands |
| nushell.enable | bool | (true if backend == "nushell") | Enable nushell |
| nushell.showBanner | bool | false | Show nushell banner on startup |
| nushell.extraConfig | lines | "" | Extra nushell configuration |

## Notes

- Setting `backend` automatically enables the corresponding shell sub-module.
- You can override individual shell enables independently of `backend` if you want multiple shells configured simultaneously.
