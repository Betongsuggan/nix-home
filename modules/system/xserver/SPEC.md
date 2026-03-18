# X Server

Enables the X11 display server with a configurable display manager and DisplayLink support. Sets up a custom session that configures multi-monitor output via xrandr.

## Usage

```nix
xserver = {
  enable = true;
  displayManager = "lightdm";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable X server |
| displayManager | str | "lightdm" | Display manager to use |

## Notes

- Video drivers are hardcoded to `["displaylink" "modesetting"]`.
- A custom session named `nixsession` is created that runs `xrandr --setprovideroutputsource 2 0` for DisplayLink multi-monitor support.
