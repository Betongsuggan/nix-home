#!/usr/bin/env python3
"""Upsert Steam non-Steam-game shortcuts for Switch ROMs, directly into
shortcuts.vdf (no Steam ROM Manager / Electron needed).

Steam mangles quoting of space-filled paths in a shortcut's LaunchOptions, so
instead of passing the ROM path as an argument we generate a tiny per-game
launcher script (path quoted internally) and point the shortcut's exe at it,
with empty LaunchOptions. Idempotent: matches existing entries by app name."""
import os
import sys
import glob
import binascii
import vdf

romdir = os.environ["SWITCH_ROMDIR"]
emu = os.environ["SWITCH_EMU"]
launch_prefix = os.environ.get("SWITCH_LAUNCH_PREFIX", "")  # e.g. '--root-data-dir "..." '
tag = os.environ.get("SWITCH_TAG", "Nintendo Switch")
hyprctl = os.environ.get("SWITCH_HYPRCTL", "hyprctl")
home = os.path.expanduser("~")

launcher_dir = os.path.join(home, ".local/share/switch-shortcuts")
os.makedirs(launcher_dir, exist_ok=True)

roots = [
    os.path.join(home, ".local/share/Steam"),
    os.path.join(home, ".steam/steam"),
    os.path.join(home, ".steam/root"),
]
config_dirs, seen = [], set()
for r in roots:
    for cfg in glob.glob(os.path.join(r, "userdata", "*", "config")):
        real = os.path.realpath(cfg)
        if real not in seen:
            seen.add(real)
            config_dirs.append(cfg)

if not config_dirs:
    sys.exit("ERROR: no Steam userdata/config dir found — log into Steam once first.")


def pick_xci(folder):
    xcis = sorted(glob.glob(os.path.join(folder, "*.xci")) +
                  glob.glob(os.path.join(folder, "*.XCI")))
    if not xcis:
        return None
    base = [x for x in xcis
            if "(UPD)" not in os.path.basename(x) and "(DLC)" not in os.path.basename(x)]
    return (base or xcis)[0]


def sanitize(name):
    return "".join(c if (c.isalnum() or c in "-_.") else "_" for c in name)


def write_launcher(name, xci):
    """Write a shell launcher: (1) fullscreen the Ryujinx window on the streamed
    monitor once it appears — the `fullscreen` window rule isn't valid in
    Hyprland 0.55, so we do it at runtime with hyprctl; (2) run the game with the
    ROM path quoted internally so Steam never has to parse it. Returns the path."""
    path = os.path.join(launcher_dir, sanitize(name) + ".sh")
    script = (
        "#!/bin/sh\n"
        "# Bring Ryujinx fullscreen on the SUNSHINE monitor once its window appears\n"
        "# (over Big Picture); otherwise it renders behind Steam and the stream\n"
        "# shows no video.\n"
        "(\n"
        "  n=0\n"
        "  while [ \"$n\" -lt 40 ]; do\n"
        "    if \"%s\" clients 2>/dev/null | grep -q 'class: Ryujinx'; then\n"
        "      \"%s\" dispatch focuswindow class:Ryujinx >/dev/null 2>&1\n"
        "      \"%s\" dispatch fullscreen 0 >/dev/null 2>&1\n"
        "      break\n"
        "    fi\n"
        "    n=$((n+1)); sleep 0.5\n"
        "  done\n"
        ") &\n"
        "exec \"%s\" %s\"%s\"\n"
    ) % (hyprctl, hyprctl, hyprctl, emu, launch_prefix, xci)
    with open(path, "w") as f:
        f.write(script)
    os.chmod(path, 0o755)
    return path


games = []
for entry in sorted(os.listdir(romdir)):
    folder = os.path.join(romdir, entry)
    if os.path.isdir(folder):
        xci = pick_xci(folder)
        if xci:
            games.append((entry, xci))

if not games:
    sys.exit(f"No .xci games found under {romdir}")


def shortcut_appid(exe, name):
    a = (binascii.crc32((exe + name).encode("utf-8")) & 0xFFFFFFFF) | 0x80000000
    return a - 0x100000000  # signed int32 for VDF


for cfg in config_dirs:
    path = os.path.join(cfg, "shortcuts.vdf")
    if os.path.exists(path):
        with open(path, "rb") as f:
            data = vdf.binary_load(f)
    else:
        data = {"shortcuts": {}}
    shortcuts = data.setdefault("shortcuts", {})
    by_name = {v.get("appname", v.get("AppName")): k for k, v in shortcuts.items()}

    for name, xci in games:
        launcher = write_launcher(name, xci)
        entry = {
            "appid": shortcut_appid(launcher, name),
            "appname": name,
            "exe": f'"{launcher}"',
            "StartDir": f'"{launcher_dir}"',
            "icon": "",
            "ShortcutPath": "",
            "LaunchOptions": "",
            "IsHidden": 0,
            "AllowDesktopConfig": 1,
            "AllowOverlay": 1,
            "OpenVR": 0,
            "Devkit": 0,
            "DevkitGameID": "",
            "DevkitOverrideAppID": 0,
            "LastPlayTime": 0,
            "FlatpakAppID": "",
            "tags": {"0": tag},
        }
        if name in by_name:
            key = by_name[name]
        else:
            nums = [int(k) for k in shortcuts.keys() if k.isdigit()]
            key = str(max(nums) + 1) if nums else "0"
        shortcuts[key] = entry

    with open(path, "wb") as f:
        vdf.binary_dump(data, f)
    print(f"Wrote {len(games)} Switch shortcut(s) to {path}")

for name, xci in games:
    print(f"  - {name}  ->  {os.path.basename(xci)}")
print("Done. Restart Steam (reconnect the Moonlight 'Steam Gaming' app) to see them.")
