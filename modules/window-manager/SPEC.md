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
- Installs a `.XCompose` file with Swedish character mappings (e.g., Compose+o+o produces o with diaeresis).
- Sets `GTK_IM_MODULE`, `QT_IM_MODULE`, and `XMODIFIERS` session variables to make `.XCompose` work in XWayland apps.
- Virtual monitors are useful for headless streaming setups (e.g., Sunshine) -- configure resolution via the `monitors` option.
