# File Manager

Unified module with system-level services and user-level configuration. The system half (`system.nix`) auto-enables when any user sets `fileManager.enable = true` — no separate system option needed.

## System layer (auto-enabled)

Installs Thunar with plugins and enables supporting system services: GVFS (virtual filesystem), Tumbler (thumbnails), udisks2 (disk management), and Polkit (privileged operations). Activates automatically when any home-manager user has `fileManager.enable = true`.

## User layer

Configurable graphical file manager with backend selection, sidebar bookmarks, and a Thunar sub-module providing custom context menu actions, thumbnail settings, archive integration, and volume management.

## Usage

```nix
# In user config only — system services are auto-enabled
fileManager = {
  enable = true;
  backend = "thunar";

  bookmarks = [
    "file:///home/user/Documents"
    "file:///home/user/Downloads"
    "file:///home/user/Development Projects"
  ];
};
```

## Options (user)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable file manager |
| backend | enum: "thunar", "nautilus", "dolphin", "pcmanfm" | "thunar" | File manager backend to use |
| bookmarks | list of string | [] | Bookmark paths for the sidebar (format: `file:///path` or `file:///path Label`) |
| terminalOverride | function or null | null | Override for terminal command with working directory; if null, uses `config.terminal.commandWithCwd` |

### Thunar sub-options

When `backend = "thunar"`, the Thunar sub-module is automatically enabled and provides additional options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| thunar.enable | bool | false (auto-enabled when backend is thunar) | Enable Thunar file manager |
| thunar.thumbnails.enable | bool | true | Enable thumbnail generation |
| thunar.thumbnails.maxFileSize | int | 100 | Maximum file size in MB for thumbnail generation |
| thunar.thumbnails.enableVideo | bool | true | Enable video thumbnails |
| thunar.thumbnails.enablePdf | bool | true | Enable PDF thumbnails |
| thunar.thumbnails.enableRaw | bool | false | Enable RAW image thumbnails |
| thunar.archive.enable | bool | true | Enable archive plugin and manager |
| thunar.archive.manager | enum: "file-roller", "xarchiver", "engrampa" | "file-roller" | Archive manager to use |
| thunar.volumeManager.enable | bool | true | Enable volume manager (thunar-volman) |
| thunar.volumeManager.autoMount | bool | true | Automatically mount removable media |
| thunar.volumeManager.autoRun | bool | false | Automatically run programs on removable media |
| thunar.defaultActions.openTerminal | bool | true | Add "Open Terminal Here" to context menu |
| thunar.defaultActions.copyPath | bool | true | Add "Copy Path" to context menu |
| thunar.defaultActions.computeChecksum | bool | false | Add "Compute SHA256" to context menu |
| thunar.defaultActions.openAsRoot | bool | false | Add "Open as Root" to context menu |
| thunar.defaultActions.setAsWallpaper | bool | false | Add "Set as Wallpaper" for images |
| thunar.customActions | list of submodule | [] | Custom context menu actions |
| thunar.view.defaultView | enum: "icon", "compact", "detailed" | "detailed" | Default view mode |
| thunar.view.showHidden | bool | false | Show hidden files by default |
| thunar.view.sortColumn | enum: "name", "size", "type", "date" | "name" | Default sort column |
| thunar.view.sortOrder | enum: "ascending", "descending" | "ascending" | Default sort order |

## Notes

- Exposes internal API options for cross-module use: `config.fileManager.open { path = "/path"; }`, `config.fileManager.select { file = "/path"; }`, and `config.fileManager.terminal { cwd = "/path"; }`.
- Bookmarks are written to `~/.config/gtk-3.0/bookmarks`.
- The Thunar sub-module writes custom actions to `~/.config/Thunar/uca.xml` and tumbler config to `~/.config/tumbler/tumbler.rc`.
- System services (xfconf, Thunar, GVFS, Tumbler, udisks2, Polkit) are enabled automatically — no need for a separate system enable.
