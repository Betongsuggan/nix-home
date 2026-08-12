# Notifications

A backend-agnostic notification system that supports dunst and mako as notification daemons. Exposes a unified `notifications.send` function that other modules can use to send notifications without knowing which backend is active.

## Usage

```nix
notifications = {
  enable = true;
  backend = "dunst";
  windowManager = "hyprland";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable notification system |
| backend | enum | "dunst" | Which notification daemon to use: "dunst", "mako" |
| windowManager | enum | "generic" | Window manager for session integration: "hyprland", "niri", "sway", "i3", "generic" |

### Backend-specific options

**dunst:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| dunst.settings | attrs | {} | Additional dunst configuration (merged with defaults) |

**mako:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| mako.settings | attrs | {} | Mako configuration |

## Notes

- Other modules can use `config.notifications.send { category = "battery"; summary = "Battery low"; body = "15% remaining"; }` to send notifications.
- **Category presets** give all notifications a coherent look. A `category` fixes the header (appName), icon, urgency, stack tag, and timeout; any of these can still be overridden per call (e.g. `urgency = "critical"` for a battery-critical alert). The clean-minimal convention: bold category header, short headline in `summary`, optional one-line detail in `body` — no emojis, no HTML field labels.

  | Category | Header | Icon | Urgency | Stack tag | Timeout |
  |----------|--------|------|---------|-----------|---------|
  | volume | Volume | audio-volume-high | low | volume | 2s |
  | brightness | Brightness | display-brightness | low | brightness | 2s |
  | media | Media | multimedia-player | low | media | 5s |
  | battery | Battery | battery | low | battery | urgency default |
  | network | Network | network-wireless | low | network | urgency default |
  | power | Power | system-shutdown | normal | power | 2s |
  | system | System | utilities-system-monitor | low | system | urgency default |
  | workspace | Workspaces | virtual-desktops | low | workspace | 3s |
  | time | Time | clock | low | time | 5s |
  | recording | Recording | media-record | normal | recording | 3s |

- The `progress` argument (0-100) renders a progress bar (dunst `int:value` hint), used by volume, brightness, and battery.
- Icon names (presets and per-call overrides) must resolve in dunst's icon path, which home-manager builds from Papirus-Light 24x24 contexts (`actions`, `apps`, `devices`, `status`, `places`, ...) but **not `panel/`** — panel-only icons like `battery-good-charging` or `network-wireless-disconnected` silently render icon-less.
- The dunst backend uses dunstify and supports features like stack tags for replacing notifications and hint-based progress bars.
- The mako backend uses notify-send from libnotify.
- The dunst backend auto-enables the launcher module for dmenu context menu support.
- Installs the Papirus icon theme for notification icons.
- Dunst font and colors come from stylix (`stylix.targets.dunst`): sans-serif font at the popup size, per-urgency base16 colors. Layout, icons, per-app rules, and timeouts remain configured in this module.
