# Autologin

Automatically logs in a specified user at boot, using either GDM (display manager) or getty (console).

## Usage

```nix
autologin = {
  enable = true;
  user = "gamer";
  method = "gdm";     # or "getty"
  session = "hyprland";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable autologin functionality |
| user | string | (required) | Username to automatically login |
| session | string | "hyprland" | Desktop session to start automatically (gdm method only) |
| method | enum: "gdm", "getty" | "gdm" | Autologin method (gdm for display manager, getty for console) |
| tty | string | "tty1" | TTY to use for getty autologin |

## Notes

- The GDM method enables GDM and uses `services.displayManager.autoLogin` with `session` as the default session.
- Sets an empty hashed password on the autologin user (as `mkDefault`). It grants no sudo rights: the autologin user is meant to be unprivileged, so a console login does not imply root.
- The getty method overrides the `getty@ttyN` systemd service to pass `--autologin` to `agetty`.
