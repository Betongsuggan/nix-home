# Autorandr

Automatic display profile switching using autorandr. Defines monitor EDID fingerprints and display profiles that are applied automatically when monitors are connected or disconnected.

## Usage

```nix
autorandr = {
  enable = true;

  monitors.laptop.edid = "00ffffffffffff004d10...";
  monitors.external.edid = "00ffffffffffff00410c...";

  profiles.laptop = {
    fingerprint = {
      eDP-1 = "00ffffffffffff004d10...";
    };
    config = {
      eDP-1 = {
        enable = true;
        primary = true;
        position = "0x0";
        mode = "1920x1200";
        rate = "59.95";
      };
    };
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Autorandr |
| monitors | attrsOf submodule | {} | Monitor definitions by name, each with an EDID fingerprint |
| monitors.\<name\>.edid | string | (required) | Monitor EDID fingerprint string |
| profiles | attrsOf submodule | {} | Display profiles with fingerprints and output configurations |
| profiles.\<name\>.fingerprint | attrsOf string | (required) | Map of output names to EDID fingerprints |
| profiles.\<name\>.config | attrsOf submodule | (required) | Configuration for each output in the profile |
| profiles.\<name\>.config.\<output\>.enable | bool | true | Whether this output is enabled |
| profiles.\<name\>.config.\<output\>.crtc | int or null | null | CRTC index |
| profiles.\<name\>.config.\<output\>.primary | bool | false | Whether this is the primary output |
| profiles.\<name\>.config.\<output\>.position | string | "0x0" | Position in format XxY |
| profiles.\<name\>.config.\<output\>.mode | string | (required) | Resolution in format WIDTHxHEIGHT |
| profiles.\<name\>.config.\<output\>.rate | string or null | null | Refresh rate |

## Notes

- Use `autorandr --fingerprint` to discover EDID fingerprints for connected monitors.
- Profiles are matched automatically based on the fingerprint of connected outputs.
