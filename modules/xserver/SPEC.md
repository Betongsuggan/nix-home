# X Server

Enables the X11 display server with a configurable display manager and optional DisplayLink support. Sets up a custom session; with DisplayLink it also routes outputs via xrandr.

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
| displayManager | enum: "lightdm", "none" | "lightdm" | Display manager to use |
| videoDrivers | list of str | ["modesetting"] | X video drivers; add "displaylink" for DisplayLink docks |

## Notes

- A custom session named `nixsession` is created. When `videoDrivers` contains "displaylink", it runs `xrandr --setprovideroutputsource 2 0` for DisplayLink multi-monitor support.
- The DisplayLink driver is unfree and must be fetched manually before it builds (see the nixpkgs `displaylink` package).
