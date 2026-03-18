# Terminal

Configures a terminal emulator with support for Alacritty, urxvt, and Ghostty backends. Provides shared font, color, and opacity settings, and exposes an internal API (`terminal.command`, `terminal.commandWithCwd`) for other modules to launch the configured terminal.

## Usage

```nix
terminal = {
  enable = true;
  backend = "ghostty";
  font.size = 14;
  opacity = 0.95;
  ghostty.extraSettings = { window-padding-x = 4; };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable terminal configuration |
| backend | enum ["alacritty" "urxvt" "ghostty"] | "alacritty" | Terminal emulator backend to use |
| font.family | nullOr str | null | Terminal font family (inherits from theme if null) |
| font.size | int | 12 | Terminal font size |
| colors.useTheme | bool | true | Use theme colors for terminal |
| opacity | float | 1.0 | Terminal background opacity (0.0 - 1.0) |
| alacritty.enable | bool | (true if backend == "alacritty") | Enable Alacritty terminal |
| alacritty.extraSettings | attrs | {} | Extra Alacritty settings |
| urxvt.enable | bool | (true if backend == "urxvt") | Enable urxvt terminal |
| urxvt.extraConfig | attrs | {} | Extra urxvt configuration |
| urxvt.keybindings | attrsOf str | (Shift-Control-V/C for clipboard) | urxvt keybindings |
| ghostty.enable | bool | (true if backend == "ghostty") | Enable Ghostty terminal |
| ghostty.extraSettings | attrs | {} | Extra Ghostty settings |
| ghostty.keybindings | listOf str | [] | Ghostty keybindings (list of "key=action" strings) |

## Notes

- Setting `backend` automatically enables the corresponding terminal sub-module.
- The `terminal.command` and `terminal.commandWithCwd` options are internal read-only values used by other modules (e.g., window-manager) to launch the configured terminal.
