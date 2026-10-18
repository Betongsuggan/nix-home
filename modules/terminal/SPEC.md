# Terminal

Configures a terminal emulator with support for Alacritty, urxvt, and Ghostty backends. Provides shared font, color, and opacity settings, and exposes an internal API (`my.terminal.command`, `my.terminal.commandWithCwd`) for other modules to launch the configured terminal.

## Usage

```nix
my.terminal = {
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
| ghostty.extraSettings | attrs | {} | Extra Ghostty settings (merged into `programs.ghostty.settings`) |
| ghostty.keybindings | listOf str | [] | Ghostty keybindings (list of "key=action" strings) |

## Clipboard

There is one clipboard, shared by every program on the desktop, and every backend here is set so that *highlighting text copies it* (`selection.save_to_clipboard` in Alacritty, `copy-on-select = clipboard` in Ghostty). Four ways in, three ways out:

| Where | Copy | Paste |
|---|---|---|
| GUI app (browser, file manager, …) | Ctrl+C | Ctrl+V |
| Terminal | highlight text, or Ctrl+Shift+C | Ctrl+Shift+V (also into Neovim's insert mode) |
| Neovim | `y` (and anything else that fills the `"` register) | `p` |
| Launcher | Mod+C picks an earlier clipboard entry | it becomes the clipboard |

Why the terminal keys differ: Ctrl+C and Ctrl+V are delivered to the program running *inside* the terminal (interrupt, and literal-next or Neovim's visual block), so a terminal cannot take them for itself; Ctrl+Shift is the convention every terminal uses instead. Neither Alacritty nor Ghostty can make Ctrl+C mean "copy if something is selected", which is why highlighting is the copy.

Neovim needs nothing from this module: the editor flake sets `clipboard = unnamedplus`, so `y`/`p` go through the system clipboard via `wl-copy` (which the compositor modules install), and over SSH it switches to OSC 52 so a yank on a remote host lands in the *local* clipboard (Alacritty's default `osc52 = OnlyCopy` and Ghostty's `clipboard-write = allow` accept it). Mouse-dragging inside Neovim selects in the editor, not the terminal; `y` it, or hold Shift to select at the terminal level.

The middle mouse button pastes a second, separate buffer, the *primary selection* ("whatever was last highlighted", in any app). Since highlighting also copies here, middle click and Ctrl+V agree after a terminal selection; after Ctrl+C in a GUI app they can differ.

Beyond this host: Mod+Shift+S sends the clipboard to another tailnet device (`modules/taildrop`).

## Notes

- Setting `backend` automatically enables the corresponding terminal sub-module.
- The `my.terminal.command` and `my.terminal.commandWithCwd` options are internal read-only values used by other modules (e.g., window-manager) to launch the configured terminal.
- **Alacritty is themed by stylix**: `colors.useTheme` toggles the stylix alacritty target (colors, font, opacity as a whole); `font.size` is wired to `stylix.fonts.sizes.terminal` and `opacity` to `stylix.opacity.terminal`. `alacritty.extraSettings` merges via the module system — use `lib.mkForce` to override a stylix-set leaf (e.g. `font.normal.style`, which stylix sets to "Regular").
- Ghostty and urxvt keep manual theming from `config.my.theming.*` (no stylix target enabled).
- Ghostty is configured through `programs.ghostty`; like alacritty, its colors, font and opacity come from stylix (`stylix.targets.ghostty`, on with `colors.useTheme`). Emoji codepoints are routed to Noto Color Emoji because Ghostty ignores fontconfig fallback.
