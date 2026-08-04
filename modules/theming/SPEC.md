# Theming

Provides a centralized theme configuration ("theme picker") for the entire desktop environment, including wallpaper, cursor, fonts, and a full 16-color palette. Stylix is the application mechanism: this module enables stylix, derives the base16 scheme, fonts, and cursor from the `theme.*` options, and enables the app-agnostic stylix targets. App modules enable their own stylix targets; manual theming from `config.theme.*` remains only where stylix has no target (e.g. niri focus ring).

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
- Sets `stylix.enable = true` with `stylix.autoEnable = false`: targets are opt-in so a flake update can't silently start theming new apps. Convention: each app module enables its own target (`stylix.targets.<app>.enable` — see alacritty, dunst, vicinae, firefox, niri/swaylock); this module owns only the app-agnostic targets:
  - `gtk` — GTK3 apps (thunar) get adw-gtk3 recolored with the base16 palette
  - `gnome` — sets dconf `color-scheme=prefer-dark`, which makes GTK4/libadwaita apps and Firefox follow dark mode (requires system-level `programs.dconf.enable`, set in `modules/common`)
  - `fontconfig` / `font-packages` — default font families and their packages
- `theme.font` drives `stylix.fonts.monospace` and the application/desktop font sizes; `theme.cursor` drives `stylix.cursor` (which sets `home.pointerCursor` with x11+gtk integration). sansSerif/serif/emoji keep stylix defaults (DejaVu + Noto Color Emoji), matching the previous manual fontconfig defaults.
- Installs Papirus icon theme (kept manual; `stylix.icons` unused), Nerd Font symbols as monospace fallback, and glibc locales. Font and cursor packages are installed via stylix.
- The wallpaper is also written to `~/.background-image` for compatibility with tools that expect it there.
- Modules for apps without a stylix target (niri focus ring, ghostty, walker, polybar) still reference `config.theme.*` directly.
