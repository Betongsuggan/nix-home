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
| vicinae.config | attrs | {} | Vicinae settings (JSON configuration) |
| vicinae.extensions | list of package | wifi-commander, bluetooth (+ hyprland-monitors under Hyprland) | List of Vicinae extensions to install |
| vicinae.themes | attrs | {} | Custom themes to add to vicinae |
| vicinae.useLayerShell | bool | true | Whether vicinae should use layer shell |

## Notes

- Other modules can use the exposed functions (`config.my.launcher.dmenu`, `config.my.launcher.show`, `config.my.launcher.wifi`, `config.my.launcher.bluetooth`, `config.my.launcher.audioOutput`, `config.my.launcher.audioInput`, `config.my.launcher.monitor`) to invoke the launcher without knowing which backend is active.
- Each backend lists the menus it provides; a menu a backend lacks is `null` in the API (`my.launcher.audioOutput` etc.), and window-manager binds for it are skipped instead of failing evaluation. Not all features are implemented for all backends. WiFi and Bluetooth menus are not yet implemented for rofi. Audio and monitor menus are only available on walker and vicinae.
- The walker backend runs as a systemd service with elephant as a dependency. The vicinae backend also runs as a systemd service.
- The vicinae backend is themed by stylix (`stylix.targets.vicinae`), which adds a "stylix" theme from the base16 palette and selects it. Walker keeps its hardcoded gruvbox CSS (no stylix target exists).
