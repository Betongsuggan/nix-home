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
- Defines the swaylock PAM service using the stock NixOS stack (pam_env, faillock, no empty passwords). When fprintd is enabled (`fingerprint.enable`), NixOS adds `pam_fprintd` as `sufficient` ahead of the password check, so either fingerprint or password unlocks.
