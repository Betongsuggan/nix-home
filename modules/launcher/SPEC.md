# Launcher

A backend-agnostic application launcher system that provides a unified interface for dmenu-style selection, application launching, WiFi/Bluetooth control, audio device selection, and monitor configuration. Supports multiple backends: wofi, rofi, walker, and vicinae.

## Usage

```nix
my.launcher = {
  enable = true;
  backend = "vicinae";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable launcher system |
| backend | enum | "vicinae" | Which launcher backend to use: "wofi", "rofi", "walker", "vicinae" |
| windowManager | enum | `my.window-manager.backend` ("generic" without one) | Window manager for session integration: "hyprland", "niri", "sway", "i3", "generic" |

### Backend-specific options

**wofi:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| wofi.settings | attrs | `{ allow_images = true; image_size = 15; }` | Additional wofi configuration |
| wofi.style | str | "" | Custom wofi CSS styling (empty uses built-in theme) |

**rofi:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| rofi.terminal | str | config.terminal.command | Terminal to use with rofi |
| rofi.theme | str | "gruvbox-dark-soft" | Rofi theme to use |

**walker:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| walker.config | attrs | {} | Walker configuration (merged with defaults) |
| walker.theme | attrs | {} | Walker theme configuration |

**vicinae:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| vicinae.config | JSON | {} | Extra settings merged into `programs.vicinae.settings` (`~/.config/vicinae/settings.json`) |
| vicinae.extensions | list of package | wifi-commander, bluetooth (+ hyprland-monitors under Hyprland) | Extensions to install (from the `vicinae-extensions` input; build more with `config.lib.vicinae.mkExtension`) |
| vicinae.themes | TOML | {} | Extra themes, keyed by theme file name |
| vicinae.useLayerShell | bool | true | Whether vicinae should use layer shell |
| vicinae.fileIndex.enable | bool | false | Run the background file indexer (file search) |
| vicinae.fileIndex.paths | list of str | `[ home ]` | Directories to index |
| vicinae.fileIndex.exclude | list of str | [] | Directories to leave out of the index |

## Notes

- Other modules can use the exposed functions (`config.my.launcher.dmenu`, `config.my.launcher.show`, `config.my.launcher.wifi`, `config.my.launcher.bluetooth`, `config.my.launcher.audioOutput`, `config.my.launcher.audioInput`, `config.my.launcher.monitor`) to invoke the launcher without knowing which backend is active.
- Each backend lists the menus it provides; a menu a backend lacks is `null` in the API (`my.launcher.audioOutput` etc.), and window-manager binds for it are skipped instead of failing evaluation. Not all features are implemented for all backends. WiFi and Bluetooth menus are not yet implemented for rofi. Audio and monitor menus are only available on walker and vicinae.
- The walker backend runs as a systemd service with elephant as a dependency. The vicinae backend also runs as a systemd service.
- vicinae is nixpkgs' package with Home Manager's `programs.vicinae` (no fork). Its `settings.json` is a read-only store link, so changes made in vicinae's settings window don't persist; everything, including provider preferences (`providers.<id>.preferences`), is set from Nix.
- The file indexer is off by default: it walks every indexed path, hidden directories included, and re-sweeps periodically (it had grown to about 2 GB over `$HOME`). With it off, file search is unavailable.
- Menus are opened with `vicinae://launch/<provider>/<command>` deeplinks; an extension's provider id is `@<author>/<name>` from its `package.json` (e.g. `@dagimg-dot/wifi-commander`), built-in commands live under `core`, and `vicinae cmd ls` lists them all. Extensions are built on their own, so a `tsconfig.json` that extends the repository root's is repointed at the root file inside the input (otherwise the bundler emits classic JSX that needs a global `React`).
- The vicinae backend is themed by stylix (`stylix.targets.vicinae`), which adds a "stylix" theme from the base16 palette and selects it. Walker keeps its hardcoded gruvbox CSS (no stylix target exists).
