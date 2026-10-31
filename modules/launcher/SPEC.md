# Launcher

The launcher is the standalone launcher flake ([github:Betongsuggan/launcher](https://github.com/Betongsuggan/launcher), input `launcher`): vicinae with the wifi, bluetooth, audio and monitor menus, and the fleet dashboard ([[fleet-status]]). This module wraps its Home Manager module (`programs.launcher`) and keeps the `my.launcher` API other modules build on. Window-manager binds for the menus stay in `my.window-manager.keybinds`; the flake's own keybind rendering is off here.

## Usage

```nix
my.launcher.enable = true;                          # on for the desktop profile
programs.launcher.vicinae.fileIndex.enable = true;  # the flake's options, directly
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the launcher |
| dmenu | function (read-only) | | `{ prompt ? null, additionalArgs ? [ ] }` -> a command reading lines on stdin and printing the choice |
| show | function (read-only) | | `{ mode }` -> the command opening that view: `applications` (`drun`, `desktopapplications`), `websearch`, `symbols` (`emoji`), `clipboard` |
| wifi, bluetooth, audioOutput, audioInput, monitor | null or function (read-only) | | `{ }` -> the command opening that menu; null when the backend has none, so window-manager binds for it are skipped |

Everything else is the flake's: `programs.launcher.vicinae.{settings,upstreamExtensions,extensions,themes,useLayerShell,fileIndex,networkTool}`, `programs.launcher.{audiomenu,monitormenu}.package`, `programs.launcher.menus` (one command per menu), `programs.launcher.package` (`launcher-menu <action>`). See the flake's README for the table.

## Notes

- The wrapper sets `programs.launcher.windowManager` from `my.window-manager.backend` (hyprland, niri, sway; null for i3) so the monitor menu knows the compositor, turns the flake's keybinds off, and passes `my.terminal.command` as the terminal (for audiomenu's mixer and the fleet SSH action).
- vicinae is themed by stylix (`stylix.targets.vicinae`, switched on here since `stylix.autoEnable` is off fleet-wide): a "stylix" theme from the base16 palette, selected in `programs.vicinae.settings`.
- Consumers of the API: `modules/window-manager` (the menu binds, `show` for sway's `menu`), `modules/taildrop`, `modules/controls/power` and `modules/notifications/dunst` (all `dmenu`).
- The audio menus (`audiomenu sink`/`source`) list the devices followed by the applications playing (or recording) with their volume. Picking a device makes it the default; picking an application opens its own menu (volume steps and presets, mute, move to another device) that returns after each change. The last entry, "Open mixer…", runs wiremix in `my.terminal`. WirePlumber's restore-stream remembers volume, mute and target per `application.name`.
- The monitor menu (`monitormenu`) changes an output at runtime: resolution, scale, rotation, placement (extend beside another output, or mirror it on Hyprland), VRR, HDR (Hyprland) and on/off. A compositor reload goes back to `my.window-manager.monitors`. Its "Show as Nix" entry copies the current state as that option's Nix.
- The upstream vicinae extensions (wifi-commander, bluetooth) are built by the flake from a pinned `vicinaehq/extensions` revision; the wifi-commander open-networks patch lives there now (`patches/`). `settings.json` is a read-only store link, so everything, provider preferences included, is set from Nix. The file indexer is off by default (it had grown to about 2 GB over `$HOME`).
- Menus open through `vicinae://launch/<provider>/<command>` deeplinks; `vicinae cmd ls` lists them.
- The rofi, wofi and walker backends were dropped with the extraction (no host used them); another backend would be added in the flake.
- Emoji (`show { mode = "symbols"; }`, Mod+E) on the vicinae backend goes through `launcher-symbols-paste`: vicinae's picker only copies (no paste action or setting), so the wrapper waits up to 30 s for the pick to land in the clipboard and types it into the focused window with `wtype` (works in terminals, which paste with Ctrl+Shift+V). Only a new, single-line value of at most 16 characters counts, so cancelling the picker and copying something else afterwards never types it. The emoji also stays in the clipboard.
