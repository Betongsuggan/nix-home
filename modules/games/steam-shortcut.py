"""Make sure Steam has a non-Steam shortcut for one command, and print the id
to launch it with (`steam steam://rungameid/<id>`).

    steam-shortcut.py check EXE NAME   exit 0 + id if every Steam account has it,
                                       1 if one is missing, 2 if Steam has no account
    steam-shortcut.py add EXE NAME     upsert it into every account, print the id

Entries are matched by exe. Steam launches a shortcut by the appid stored in
shortcuts.vdf (not one derived from exe+name), so an existing entry keeps its
appid: Steam Input layouts and play time hang off it. Steam rewrites
shortcuts.vdf from memory on exit, so `add` must run while Steam is stopped."""
import binascii
import glob
import os
import sys

import vdf

mode, exe, name = sys.argv[1:4]
configs = sorted(glob.glob(os.path.expanduser("~/.local/share/Steam/userdata/*/config")))
if not configs:
    sys.exit(2)


def load(cfg):
    path = os.path.join(cfg, "shortcuts.vdf")
    if not os.path.exists(path):
        return path, {"shortcuts": {}}
    with open(path, "rb") as f:
        return path, vdf.binary_load(f)


def find(shortcuts):
    for key, v in shortcuts.items():
        if (v.get("Exe") or v.get("exe") or "").strip('"') == exe:
            return key
    return None


def rungameid(appid):
    return ((appid & 0xFFFFFFFF) << 32) | 0x02000000


appids = []
for cfg in configs:
    path, data = load(cfg)
    shortcuts = data.setdefault("shortcuts", {})
    key = find(shortcuts)
    if mode == "check":
        if key is None:
            sys.exit(1)
        appids.append(shortcuts[key]["appid"])
        continue

    old = shortcuts.get(key, {}) if key is not None else {}
    # Signed int32 in the vdf; Steam's own formula for new shortcuts
    default = ((binascii.crc32(f'"{exe}"{name}'.encode()) & 0xFFFFFFFF) | 0x80000000) - 0x100000000
    entry = {
        "appid": old.get("appid", default),
        "AppName": name,
        "Exe": f'"{exe}"',
        "StartDir": f'"{os.path.dirname(exe)}"',
        "icon": old.get("icon", ""),
        "ShortcutPath": "",
        "LaunchOptions": "",
        "IsHidden": 0,
        "AllowDesktopConfig": 1,
        "AllowOverlay": 1,
        "OpenVR": 0,
        "Devkit": 0,
        "DevkitGameID": "",
        "DevkitOverrideAppID": 0,
        "LastPlayTime": old.get("LastPlayTime", 0),
        "FlatpakAppID": "",
        "tags": old.get("tags", {}),
    }
    if key is None:
        nums = [int(k) for k in shortcuts if k.isdigit()]
        key = str(max(nums) + 1) if nums else "0"
    shortcuts[key] = entry
    with open(path, "wb") as f:
        vdf.binary_dump(data, f)
    appids.append(entry["appid"])

print(rungameid(appids[0]))
