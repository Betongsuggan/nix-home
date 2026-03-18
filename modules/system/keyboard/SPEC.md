# Keyboard

Enables keyboard customization using Kanata. Configures home row modifiers with tap-hold behavior on the internal keyboard, mapping home row keys to modifier keys when held.

## Usage

```nix
keyboard.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable keyboard customization |

## Notes

- Uses Kanata for key remapping with `process-unmapped-keys` enabled so non-remapped keys pass through normally.
- Home row modifier layout:
  - Left hand: `a`=Meta, `s`=Alt, `d`=Ctrl, `f`=Shift (hold)
  - Right hand: `j`=Shift, `k`=Ctrl, `l`=Alt, `;`=Meta (hold)
- Meta keys use one-shot behavior (400ms timeout), meaning a single press-and-release activates the modifier for the next keypress only.
- The `uinput` kernel module and group are configured automatically for Kanata's virtual keyboard device.
