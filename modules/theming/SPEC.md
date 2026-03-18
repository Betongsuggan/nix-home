# Theming

Provides a centralized theme configuration for the entire desktop environment, including wallpaper, cursor, fonts, and a full 16-color palette. Integrates with Stylix for base16 scheme generation and configures fontconfig defaults.

## Usage

```nix
theme = {
  enable = true;
  wallpaper = ./my-wallpaper.png;
  font = {
    name = "JetBrains Mono";
    package = pkgs.jetbrains-mono;
    size = 12.0;
  };
  colors.primary.background = "#1d2021";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable theme |
| wallpaper | path | (built-in nix-background.png) | Path to wallpaper image |
| cursor.package | attrs | pkgs.bibata-cursors | Cursor theme package |
| cursor.name | str | "Bibata-Modern-Classic" | Name of the cursor theme |
| cursor.size | int | 24 | Size of the cursor |
| font.package | package | pkgs.hasklig | Font package |
| font.name | str | "Hasklig" | Name of the font to use |
| font.style | str | "Medium" | Style of the font to use |
| font.size | number | 11.0 | Size of the font |
| colors.primary.background | str | "#282828" | Primary background color |
| colors.primary.foreground | str | "#ebdbb2" | Primary foreground color |
| colors.normal.black | str | "#282828" | Normal black color |
| colors.normal.red | str | "#cc241d" | Normal red color |
| colors.normal.green | str | "#98971a" | Normal green color |
| colors.normal.yellow | str | "#d79921" | Normal yellow color |
| colors.normal.blue | str | "#458588" | Normal blue color |
| colors.normal.magenta | str | "#b16286" | Normal magenta color |
| colors.normal.cyan | str | "#458588" | Normal cyan color |
| colors.normal.white | str | "#cccccc" | Normal white color |
| colors.bright.black | str | "#3c3836" | Bright black color |
| colors.bright.red | str | "#fb4934" | Bright red color |
| colors.bright.green | str | "#b8bb26" | Bright green color |
| colors.bright.yellow | str | "#fabd2f" | Bright yellow color |
| colors.bright.blue | str | "#83a598" | Bright blue color |
| colors.bright.magenta | str | "#d3869b" | Bright magenta color |
| colors.bright.cyan | str | "#83a598" | Bright cyan color |
| colors.bright.white | str | "#ffffff" | Bright white color |

## Notes

- The default color scheme is Gruvbox Dark.
- Installs Papirus icon theme, Nerd Font symbols, Noto Color Emoji, and DejaVu fonts alongside the configured font.
- Configures Stylix with a base16 scheme derived from the color options and enables GTK theming.
- The wallpaper is also written to `~/.background-image` for compatibility with tools that expect it there.
- Other modules (terminal, waybar, zellij) reference `config.theme.*` to inherit colors and fonts.
