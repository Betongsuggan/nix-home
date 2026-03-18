# Undervolting

Enables AMD GPU undervolting and overclocking tools. Installs CoreCtrl for GUI-based GPU management and unlocks all AMD GPU power-play features via the `ppfeaturemask`.

## Usage

```nix
undervolting.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable undervolting tools |

## Notes

- Enables `corectrl` for GUI-based GPU frequency/voltage control.
- Sets `ppfeaturemask = "0xffffffff"` to unlock all AMD GPU overdrive features.
- AMD GPU specific -- not applicable to NVIDIA or Intel GPUs.
