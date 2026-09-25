# Theming

Provides a centralized theme configuration ("theme picker") for the entire desktop environment: a color scheme, wallpaper, cursor and fonts. Stylix is the application mechanism: this module enables stylix with the scheme's canonical base16 file (from `pkgs.base16-schemes`), fonts and cursor, and enables the app-agnostic stylix targets. The editor uses the scheme's own Neovim colorscheme (`modules/editor`). App modules enable their own stylix targets; manual theming from `config.my.theming.*` remains only where stylix has no target (e.g. niri focus ring).

## Usage

```nix
my.theming = {
  enable = true;
  wallpaper = ./my-wallpaper.png;
  font = {
    name = "JetBrains Mono";
    package = pkgs.jetbrains-mono;
    size = 12.0;
  };
  scheme = "kanagawa";   # gruvbox (default) or kanagawa
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable theme |
| wallpaper | path | `assets/wallpaper/zeal.jpg` | Path to wallpaper image |
| cornerRadius | int | 5 | Corner radius (px) used by Hyprland, niri, waybar and wofi |
| cursor.package | package | pkgs.banana-cursor | Cursor theme package |
| cursor.name | str | "Banana" | Name of the cursor theme |
| cursor.size | int | 24 | Size of the cursor |
| font.package | package | pkgs.hasklig | Font package |
| font.name | str | "Hasklig" | Name of the font to use |
| font.style | str | "Medium" | Style of the font to use |
| font.size | number | 11.0 | Size of the font |
| scheme | enum (schemes.nix) | "gruvbox" | Color scheme: the base16 scheme stylix uses, the editor's colorscheme and the `colors` palette |
| colors.{primary.{background,foreground},normal.*,bright.*,gray,orange} | str | the scheme's terminal palette | Colors for modules stylix doesn't theme (waybar, wofi, polybar, niri, Hyprland borders); override single colors per host |

## Notes

- The default color scheme is gruvbox (dark, medium contrast).
- Sets `stylix.enable = true` with `stylix.autoEnable = false`: targets are opt-in so a flake update can't silently start theming new apps. Convention: each app module enables its own target (`stylix.targets.<app>.enable` — see alacritty, dunst, vicinae, firefox, niri/swaylock); this module owns only the app-agnostic targets:
  - `gtk` — GTK3 apps (thunar) get adw-gtk3 recolored with the base16 palette
  - `gnome` — sets dconf `color-scheme=prefer-dark`, which makes GTK4/libadwaita apps and Firefox follow dark mode (requires system-level `programs.dconf.enable`, set in `modules/common`)
  - `fontconfig` / `font-packages` — default font families and their packages
- `my.theming.font` drives `stylix.fonts.monospace` and the application/desktop font sizes; `my.theming.cursor` drives `stylix.cursor` (which sets `home.pointerCursor` with x11+gtk integration). sansSerif/serif/emoji keep stylix defaults (DejaVu + Noto Color Emoji), matching the previous manual fontconfig defaults.
- Installs Papirus icon theme (kept manual; `stylix.icons` unused), and Nerd Font symbols as monospace fallback (locales come from NixOS). Font and cursor packages are installed via stylix.
- The wallpaper is also written to `~/.background-image` for compatibility with tools that expect it there.
- Modules for apps without a stylix target (niri focus ring, ghostty, walker, polybar) still reference `config.my.theming.*` directly.
- Apps with a stylix target use the scheme's base16 file (alacritty, ghostty, sway, i3, swaylock, zellij, mako, xresources, vicinae, ...); the rest (hyprlock, niri focus ring, waybar and wofi CSS, polybar) read `my.theming.colors` directly.
- Schemes live in `schemes.nix`: `gruvbox` (gruvbox dark medium) and `kanagawa` (wave). Each names its base16 scheme file, its Neovim colorscheme, and its terminal palette. Adding a scheme is one entry there, plus its colorscheme in the nvim flake's `theme.colorscheme`.
- stylix gets the canonical base16 scheme rather than one assembled from the terminal palette: base16's slots mean background shades, comments, line numbers and syntax roles, which a terminal's normal/bright colors don't map onto (the earlier mapping had base00 = base01 and white in base04/06/07).

