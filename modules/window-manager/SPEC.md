# Window Manager

Configures a tiling window manager with support for Hyprland, i3, Niri, and Sway backends. Provides shared options for monitor setup, workspace bindings, autostart applications, compose key, and touchscreen mapping that apply across all backends.

## Usage

```nix
windowManager = {
  enable = true;
  backend = "hyprland";
  monitors = [
    "DP-1,3440x1440@100,0x0,1"
    "HDMI-A-1,3840x2160@120,auto,2"
  ];
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
| monitors | listOf str | [",preferred,auto,1"] | Monitor configuration strings (Hyprland format: "name,resolution@refresh,position,scale") |
| virtualMonitors | listOf str | [] | Virtual/headless monitor names to create at startup (e.g., for Sunshine streaming) |
| workspaceBindings | listOf submodule | [] | Bind workspaces to specific monitors |
| workspaceBindings.*.workspace | int | (required) | Workspace number |
| workspaceBindings.*.monitor | str | (required) | Monitor name (e.g., DP-1) |
| workspaceBindings.*.default | bool | false | Make this the default workspace for the monitor |
| composeKey | str | "ralt" | Keyboard key to use as the compose key for special characters |
| touchOutput | nullOr str | null | Output name to map touchscreen input to (e.g., "eDP-1") |

## Notes

- Setting `backend` automatically enables the corresponding window manager sub-module (hyprland, i3, niri, or sway).
- The hyprland backend uses Hyprland's built-in `scrolling` layout (≥0.55) configured to mimic niri's default scrollable tiling: columns on an infinite horizontal strip, new windows as new 50%-width columns. Navigation stops at the ends like niri: no focus wrap (`general:no_focus_fallback`), no monitor hop at the strip edge (`binds:window_direction_monitor_fallback = false`), and workspace stepping goes through the `hypr-workspace-step` helper script since Hyprland's `m±1` selector wraps unconditionally. Binds mirror the niri sub-module's layout: Mod+H/L focus across columns, Mod+K/J focus workspace up/down, Mod+Shift+H/L move column, Mod+Shift+K/J move to workspace up/down (window only — Hyprland can't move a whole column across workspaces), Mod+Ctrl+K/J focus within a column, Mod+Ctrl+Shift+K/J move window within a column, Mod+Minus/Equal column width ±0.1, Mod+Shift+Minus/Equal window height ±10%, Mod+F maximize-column toggle (column width 1.0 ↔ 0.5 via a helper script, stays tiled with borders/gaps), Mod+Shift+F fullscreen toggle, Mod+R cycle preset widths (0.333/0.5/0.667/1.0), Mod+Comma/Period consume/expel a window into/out of the column, Mod+Ctrl+C center column (Mod+C is the clipboard launcher). Workspace switches animate vertically (`slidevert`, which also makes the workspace swipe gesture vertical), matching niri's stacked-workspace visual. Built-in window rules float the xdg-desktop-portal-hyprland screen-share picker and browsers' "is sharing your screen" indicator bubbles (unusable when tiled into a column); `hyprland.windowRules` appends to these. Screen sharing uses the stock portal flow (app picker + hyprland-share-picker) with `screencopy:allow_token_by_default = true` in `xdph.conf`: restore tokens stop Electron apps (Slack) from re-popping the picker on every thumbnail refresh, while keeping full monitor/window choice on each new selection. (A `custom_picker_binary` auto-picker was tried earlier and rolled back — it broke Slack huddle sharing.) Workspaces can opt back into dwindle via workspace rules.
- The pointer cursor (`home.pointerCursor`) is provided by stylix from `theme.cursor` (see theming module); the hyprland sub-module only adds the hyprcursor part stylix doesn't manage.
- Niri's swaylock lock screen: wallpaper and colors come from the stylix swaylock target; swaylock-effects extras (blur, vignette, clock, indicator, font) stay in the niri sub-module. The niri focus ring still reads `config.theme.*` directly (no stylix niri target).
- Installs a `.XCompose` file with Swedish character mappings (e.g., Compose+o+o produces o with diaeresis).
- Sets `GTK_IM_MODULE`, `QT_IM_MODULE`, and `XMODIFIERS` session variables to make `.XCompose` work in XWayland apps.
- Virtual monitors are useful for headless streaming setups (e.g., Sunshine) -- configure resolution via the `monitors` option.
- Hyprland lid switch handling is external-display-aware (`hypr-lid-switch`): with an external monitor connected, lid close disables the internal panel (eDP*) and work continues on the external screen; with the panel alone, lid close locks (hyprlock) and blanks before logind suspends. Lid open re-enables the panel and dpms. Complements the logind lid settings in the power-management module.
- A companion user service (`hypr-monitor-watch`, bound to hyprland-session.target) watches Hyprland's socket2 for `monitorremoved`: if the last external monitor is unplugged while the internal panel is disabled (lid closed), it re-enables the panel — Hyprland wedges with zero enabled outputs — and suspends if the lid is closed, since unplugging is not a lid event logind would act on.
