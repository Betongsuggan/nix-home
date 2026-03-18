# Wayland Security

Configures security services for Wayland compositors, including Polkit for privilege escalation and screen-lock PAM integration. Enables hyprlock and configures swaylock with optional fingerprint authentication.

## Usage

```nix
wayland-security.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Wayland security configuration |

## Notes

- Enables Polkit for graphical privilege escalation prompts.
- Enables hyprlock for Hyprland screen locking.
- When `fingerprint.enable` is true, configures swaylock PAM to accept either fingerprint or password (not both required).
