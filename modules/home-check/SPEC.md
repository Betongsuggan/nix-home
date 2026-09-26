# Home Check

Keeps the home layout from drifting. `home-check` reports what is out of place in `~` and where each item belongs; a weekly user timer sends a notification when it finds anything. It never moves or deletes anything.

## Usage

On with the desktop profile. Allow the host's own top-level folders per user:

```nix
my.home-check.allowed = [ "Games" "roms" "emulation" ];
```

Run `home-check` for the report. `home-check --summary` prints only the number of findings.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | `my.profiles.desktop.enable` | Install `home-check` and its weekly timer |
| allowed | list of str | XDG folders + Development, nix-home, nix-vault | Top-level entries of `~` that belong there (entries you add join the defaults) |
| downloadsAge | int | 30 | Report downloads older than this many days |
| buildOutput.roots | list of str | `[ "~/Development" ]` | Where to look for build output |
| buildOutput.names | list of str | target, node_modules, .direnv, .gradle, `__pycache__`, dist, .next, cdk.out | Regenerable build folder names |
| buildOutput.minSize | int (MB) | 50 | Smallest build folder to report |
| buildOutput.staleAfter | int (days) | 30 | Report build folders where nothing, two levels down, changed for this long |

## Checks

1. **Not part of the home layout**: non-hidden top-level entries of `~` that aren't allowed. Files get a destination by extension (images → Pictures, video → Videos, audio → Music, archives and images → Downloads, anything else → Documents). Folders are suggested to go under Documents or be allowed. Symlinks are shown with their target.
2. **Captures outside their folders**: screenshot-like names (the window manager's ISO-date names, `Screenshot*`) directly in `~`, Pictures, Videos, Downloads or Desktop. They belong in `~/Pictures/Screenshots`, or `~/Videos/Recordings` for video.
3. **Old downloads**: the count and size of Downloads entries older than `downloadsAge`.
4. **Stale build output**: build folders of at least `minSize` MB, largest first. These are regenerable, so they're safe to clean by hand.

The weekly timer is `home-check.timer` (persistent, so a missed run happens at the next login). It only notifies.
