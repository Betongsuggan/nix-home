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

- Other modules can use `config.notifications.send { summary = "Title"; body = "Message"; urgency = "normal"; }` to send notifications.
- The dunst backend uses dunstify and supports features like stack tags for replacing notifications and hint-based progress bars.
- The mako backend uses notify-send from libnotify.
- The dunst backend auto-enables the launcher module for dmenu context menu support.
- Installs the Papirus icon theme for notification icons.
