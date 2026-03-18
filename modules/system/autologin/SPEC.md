# Autologin

Automatically logs in a specified user at boot, using either GDM (display manager) or getty (console). Configures passwordless sudo for the autologin user.

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
| session | string | "hyprland" | Desktop session to start automatically |
| method | enum: "gdm", "getty" | "gdm" | Autologin method (gdm for display manager, getty for console) |
| tty | string | "tty1" | TTY to use for getty autologin |

## Notes

- The GDM method requires the `wayland` module to be enabled (`config.wayland.enable`).
- Sets an empty hashed password on the autologin user and grants passwordless sudo for all commands.
- The getty method overrides the `getty@ttyN` systemd service to pass `--autologin` to `agetty`.
