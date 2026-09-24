# Window Manager

Configures a tiling window manager with support for Hyprland, i3, Niri, and Sway backends. Provides shared options for monitor setup, workspace bindings, autostart applications, compose key, and touchscreen mapping that apply across all backends.

## Usage

```nix
my.window-manager = {
  enable = true;
  backend = "hyprland";
  monitors = {
    DP-1 = {
      mode = { width = 3440; height = 1440; refresh = 100; };
      position = { x = 0; y = 0; };
    };
    HDMI-A-1 = {
      mode = { width = 3840; height = 2160; refresh = 120; };
      scale = 2;
      hdr = true;      # Hyprland only, like bitdepth / sdrBrightness / sdrSaturation
    };
    DP-3.enable = false;
  };
  autostartApps = {
    browser = { command = "firefox"; workspace = 1; };
    chat = { command = "slack"; workspace = 3; };
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable window manager configuration |
| backend | enum ["hyprland" "i3" "niri" "sway"] | "hyprland" | Window manager backend to use |
| autostartApps | attrsOf submodule | {} | Applications to autostart with optional workspace assignment |
| autostartApps.\<name\>.command | str | (required) | Command to execute |
| autostartApps.\<name\>.workspace | nullOr int | null | Workspace number to launch the application in |
| monitors | attrsOf submodule | {} | Outputs by connector name: `enable`, `mode` ({ width, height, refresh }; null = preferred), `position` ({ x, y }; null = auto), `scale`, `vrr`, and the Hyprland-only `hdr`, `bitdepth`, `sdrBrightness`, `sdrSaturation`. Unlisted outputs use their preferred mode at scale 1. Each backend renders this itself (Hyprland `monitor` rules, niri `outputs`, sway `output` lines, xrandr for i3). |
| virtualMonitors | listOf str | [] | Virtual/headless monitor names to create at startup (e.g., for Sunshine streaming) |
| workspaceBindings | listOf submodule | [] | Bind workspaces to specific monitors |
| workspaceBindings.*.workspace | int | (required) | Workspace number |
| workspaceBindings.*.monitor | str | (required) | Monitor name (e.g., DP-1) |
| workspaceBindings.*.default | bool | false | Make this the default workspace for the monitor |
| composeKey | str | "ralt" | Keyboard key to use as the compose key for special characters |
| touchOutput | nullOr str | null | Output name to map touchscreen input to (e.g., "eDP-1") |
| idle.dimAfter / lockAfter / screenOffAfter / suspendAfter | int (s) | 240 / 300 / 330 / 900 | Idle timeouts, shared by hypridle (Hyprland) and swayidle (niri) |

## Keymap

One keymap, `my.window-manager.keybinds` (internal, defined in `home.nix`), rendered by every backend in its own syntax: Hyprland `bind`/`binde`, niri `binds`, and i3/sway `keybindings` on top of their defaults. An entry is either a command run the same way everywhere (`spawn`) or a native action per compositor; a compositor without one leaves the chord unbound, as does a launcher menu the launcher backend lacks.

| Keys | Action |
|---|---|
| Mod+Return / Mod+Shift+Q | terminal / close window |
| Mod+H/L, Mod+K/J | focus column left/right, workspace up/down |
| Mod+Shift+H/L, Mod+Shift+K/J | move column left/right, to workspace up/down |
| Mod+Ctrl+K/J, Mod+Ctrl+Shift+K/J | focus / move window within the column |
| Mod+Ctrl+H/L, Mod+Ctrl+Shift+H/L | focus monitor, move to monitor |
| Mod+Minus/Equal, Mod+Shift+Minus/Equal | column width, window height |
| Mod+F / Mod+Shift+F | maximize column / fullscreen |
| Mod+Comma/Period | consume into / expel from column |
| Mod+1..0, Mod+Shift+1..0 | focus / move to workspace |
| Mod+Shift+X / Mod+Ctrl+X | lock / lock via power-control |
| Mod+Escape, Mod+Shift+Escape, Mod+Ctrl+S | power menu, power status, suspend |
| Mod+Shift+P / Mod+Ctrl+P | screenshot region / focused output |
| Mod+V / Mod+Shift+V | toggle recording of a region / the focused output (`screen-record`) |
| Mod+B, Mod+Space, Mod+W, Mod+T | battery, system, workspace, clock notifiers |
| Mod+S, Mod+N, Mod+P (+ XF86 media keys) | play/pause, next, previous |
| Mod+O, D, E, C, U, Z, M, A, Shift+A | launcher: apps, web search, symbols, clipboard, wifi, bluetooth, monitors, audio out/in |
| Hyprland only: Mod+R, Mod+Ctrl+C, Mod+Shift+B/C | cycle column widths, center column, QWERTY/Colemak |
| niri only: Mod+Tab, Mod+Shift+E | overview, quit |

## Notes

- Setting `backend` automatically enables the corresponding window manager sub-module (hyprland, i3, niri, or sway).
- The hyprland backend uses Hyprland's built-in `scrolling` layout (≥0.55) configured to mimic niri's default scrollable tiling: columns on an infinite horizontal strip, new windows as new 50%-width columns. Navigation stops at the ends like niri: no focus wrap (`general:no_focus_fallback`), no monitor hop at the strip edge (`binds:window_direction_monitor_fallback = false`), and workspace stepping goes through the `hypr-workspace-step` helper script since Hyprland's `m±1` selector wraps unconditionally. Binds mirror the niri sub-module's layout: Mod+H/L focus across columns, Mod+K/J focus workspace up/down, Mod+Shift+H/L move column, Mod+Shift+K/J move to workspace up/down (window only — Hyprland can't move a whole column across workspaces), Mod+Ctrl+K/J focus within a column, Mod+Ctrl+Shift+K/J move window within a column, Mod+Minus/Equal column width ±0.1, Mod+Shift+Minus/Equal window height ±10%, Mod+F maximize-column toggle (column width 1.0 ↔ 0.5 via a helper script, stays tiled with borders/gaps), Mod+Shift+F fullscreen toggle, Mod+R cycle preset widths (0.333/0.5/0.667/1.0), Mod+Comma/Period consume/expel a window into/out of the column, Mod+Ctrl+C center column (Mod+C is the clipboard launcher). Workspace switches animate vertically (`slidevert`), matching niri's stacked-workspace visual, and a 3-finger vertical touchpad swipe scrolls through workspaces (`gesture = 3, vertical, workspace`, the ≥0.51 gesture syntax) with `workspace_swipe_invert = false` so the viewport follows the fingers; 3-finger horizontal swipes step focus through the scrolling layout's columns (`dispatcher, movefocus` gestures — discrete, as Hyprland has no smooth layout-scroll gesture action). Built-in window rules float the xdg-desktop-portal-hyprland screen-share picker and browsers' "is sharing your screen" indicator bubbles (unusable when tiled into a column); `my.window-manager.hyprland.windowRules` appends to these. Screen sharing uses the stock portal flow (app picker + hyprland-share-picker) with `screencopy:allow_token_by_default = true` in `xdph.conf`: restore tokens stop Electron apps (Slack) from re-popping the picker on every thumbnail refresh, while keeping full monitor/window choice on each new selection. (A `custom_picker_binary` auto-picker was tried earlier and rolled back — it broke Slack huddle sharing.) Workspaces can opt back into dwindle via workspace rules.
- The pointer cursor (`home.pointerCursor`) is provided by stylix from `my.theming.cursor` (see theming module); the hyprland sub-module only adds the hyprcursor part stylix doesn't manage.
- Niri's swaylock lock screen: wallpaper and colors come from the stylix swaylock target; swaylock-effects extras (blur, vignette, clock, indicator, font) stay in the niri sub-module. The niri focus ring still reads `config.my.theming.*` directly (no stylix niri target).
- Installs a `.XCompose` file with Swedish character mappings (e.g., Compose+o+o produces o with diaeresis).
- Sets `GTK_IM_MODULE`, `QT_IM_MODULE`, and `XMODIFIERS` session variables to make `.XCompose` work in XWayland apps.
- Virtual monitors are useful for headless streaming setups (e.g., Sunshine) -- configure resolution via the `monitors` option.
- Hyprland lid switch handling is external-display-aware (`hypr-lid-switch`): with an external monitor connected, lid close disables the internal panel (eDP*) and work continues on the external screen. With the panel alone, lid close does nothing in the script — logind suspends (HandleLidSwitch in power-management) and hypridle locks via its before-sleep hook (under a sleep inhibitor) and runs dpms on after resume. (Spawning hyprlock/blanking from the lid script raced the suspend freeze and could leave the panel black on resume.) Lid open re-enables the panel and dpms. Complements the logind lid settings in the power-management module.
- A companion user service (`hypr-monitor-watch`, bound to hyprland-session.target) watches Hyprland's socket2 for `monitorremoved`: if the last external monitor is unplugged while the internal panel is disabled (lid closed), it re-enables the panel — Hyprland wedges with zero enabled outputs — and suspends if the lid is closed, since unplugging is not a lid event logind would act on.
- `nixos.nix` (system half) configures xdg-desktop-portal from the backends the host's users run (via `lib.anyHomeUser`): Hyprland gets the gtk portal with `config.common.default = "*"`, niri gets the gtk + gnome portals and its own `niri-portals.conf`. Hosts no longer declare portals themselves.
- Enabling a window manager enables `my.launcher`, `my.controls` and `my.notifications` (mkDefault); those modules read the backend from `my.window-manager.backend` themselves.
