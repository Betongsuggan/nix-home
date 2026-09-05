#!/usr/bin/env python3
"""Upsert Steam non-Steam-game shortcuts for Switch ROMs, directly into
shortcuts.vdf (no Steam ROM Manager / Electron needed).

Steam mangles quoting of space-filled paths in a shortcut's LaunchOptions, so
instead of passing the ROM path as an argument we generate a tiny per-game
launcher script (path quoted internally) and point the shortcut's exe at it,
with empty LaunchOptions. Idempotent: matches existing entries by app name.

If SWITCH_SGDB_KEY_FILE points at a readable SteamGridDB API key, artwork
(portrait/wide capsules, hero, logo, icon) is fetched per game into each
config dir's grid/ folder. Artwork failures never fail shortcut creation."""
import os
import sys
import glob
import json
import time
import binascii
import urllib.error
import urllib.parse
import urllib.request
import vdf

romdir = os.environ["SWITCH_ROMDIR"]
emu = os.environ["SWITCH_EMU"]
launch_prefix = os.environ.get("SWITCH_LAUNCH_PREFIX", "")  # e.g. '--root-data-dir "..." '
tag = os.environ.get("SWITCH_TAG", "Nintendo Switch")
hyprctl = os.environ.get("SWITCH_HYPRCTL", "hyprctl")
sgdb_key_file = os.environ.get("SWITCH_SGDB_KEY_FILE", "")
artwork_force = os.environ.get("SWITCH_ARTWORK_FORCE", "") == "1"
home = os.path.expanduser("~")

sgdb_key = None
if sgdb_key_file:
    try:
        with open(sgdb_key_file) as f:
            sgdb_key = f.read().strip() or None
        if sgdb_key is None:
            print(f"WARNING: SteamGridDB key file {sgdb_key_file} is empty; skipping artwork.")
        else:
            # Masked fingerprint so key problems (truncation, stray quoting,
            # wrong vault entry) are diagnosable without leaking the secret
            # into logs Steam/systemd might capture.
            masked = f"{sgdb_key[:4]}…{sgdb_key[-4:]}" if len(sgdb_key) > 8 else "<too short>"
            print(f"SteamGridDB artwork enabled (key {masked}, {len(sgdb_key)} chars, from {sgdb_key_file})")
    except OSError as e:
        print(f"WARNING: cannot read SteamGridDB key file: {e}; skipping artwork.")

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


# --- SteamGridDB artwork ----------------------------------------------------
# Steam shows custom art for a non-Steam shortcut when files named after the
# shortcut's *unsigned* appid exist in userdata/<id>/config/grid/:
#   {appid}p.*      portrait capsule (library tile)
#   {appid}.*       wide capsule (Big Picture / recents)
#   {appid}_hero.*  hero banner (game page background)
#   {appid}_logo.*  logo (drawn over the hero)
# The icon is a regular file referenced by the shortcut's `icon` vdf field;
# we keep it in grid/ as {appid}_icon.* for tidiness.

SGDB_API = "https://www.steamgriddb.com/api/v2"
# Cloudflare in front of steamgriddb.com blocks urllib's default
# "Python-urllib/3.x" user agent with a 403 (error code 1010), so every
# request must carry a real UA string.
SGDB_UA = "switch-add-shortcuts/1.0 (+https://github.com/Betongsuggan/nix-home)"

# kind -> (endpoint, preferred query filters, grid basename pattern)
ART_KINDS = [
    ("portrait", "/grids/game/{id}", "dimensions=600x900&mimes=image/png,image/jpeg&types=static", "{appid}p"),
    ("wide", "/grids/game/{id}", "dimensions=460x215,920x430&mimes=image/png,image/jpeg&types=static", "{appid}"),
    ("hero", "/heroes/game/{id}", "mimes=image/png,image/jpeg&types=static", "{appid}_hero"),
    ("logo", "/logos/game/{id}", "mimes=image/png,image/jpeg&types=static", "{appid}_logo"),
    ("icon", "/icons/game/{id}", "mimes=image/png&types=static", "{appid}_icon"),
]
ART_EXTS = (".png", ".jpg", ".jpeg", ".ico", ".webp")

_sgdb_id_cache = {}
_asset_url_cache = {}


def sgdb_json(path):
    req = urllib.request.Request(
        SGDB_API + path,
        headers={"Authorization": "Bearer " + sgdb_key, "User-Agent": SGDB_UA})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.load(r)["data"]
    except urllib.error.HTTPError as e:
        # Surface the API's error body (e.g. why a 403 was returned) in the
        # warning instead of just the bare status code.
        try:
            e.msg = f"{e.msg} — {e.read().decode(errors='replace')[:200]}"
        except Exception:
            pass
        raise


def sgdb_game_id(name, folder):
    """SGDB game id for a ROM folder: a `.sgdbid` file in the folder wins
    (escape hatch for bad name matches), otherwise first autocomplete hit.
    Logs the matched title so silent mismatches are visible in the output."""
    if name in _sgdb_id_cache:
        return _sgdb_id_cache[name]
    gid = None
    override = os.path.join(folder, ".sgdbid")
    if os.path.exists(override):
        with open(override) as f:
            gid = int(f.read().strip())
        print(f"  {name}: using SteamGridDB id {gid} from .sgdbid")
    else:
        results = sgdb_json("/search/autocomplete/" + urllib.parse.quote(name))
        if results:
            gid = results[0]["id"]
            print(f"  {name}: matched SteamGridDB entry \"{results[0]['name']}\" (id {gid})")
        else:
            print(f"  WARNING: {name}: no SteamGridDB match — no artwork")
    _sgdb_id_cache[name] = gid
    return gid


def sgdb_asset_url(gid, kind, endpoint, query):
    """URL of the top-voted asset of one kind, cached across config dirs.
    The filter params are retried without filters on a 4xx in case the API
    rejects them."""
    ck = (gid, kind)
    if ck in _asset_url_cache:
        return _asset_url_cache[ck]
    path = endpoint.format(id=gid)
    try:
        data = sgdb_json(path + "?" + query)
    except urllib.error.HTTPError:
        data = sgdb_json(path)
    url = data[0]["url"] if data else None
    _asset_url_cache[ck] = url
    time.sleep(0.25)  # rate-limit politeness
    return url


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": SGDB_UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        body = r.read()
    with open(dest + ".part", "wb") as f:
        f.write(body)
    os.replace(dest + ".part", dest)  # atomic: no half-written grid files


def existing_art(grid, base):
    for ext in ART_EXTS:
        p = os.path.join(grid, base + ext)
        if os.path.exists(p):
            return p
    return None


def fetch_artwork(cfg, appid_u, name, folder):
    """Fetch all art kinds for one game into cfg/grid/. Returns the icon path
    ('' if unavailable). Existing files are kept unless SWITCH_ARTWORK_FORCE=1.
    Never raises — shortcuts must be written even when artwork fails."""
    if not sgdb_key:
        return ""
    grid = os.path.join(cfg, "grid")
    os.makedirs(grid, exist_ok=True)
    try:
        gid = sgdb_game_id(name, folder)
    except Exception as e:
        print(f"  WARNING: {name}: SteamGridDB search failed: {e}")
        return ""
    if gid is None:
        return ""
    icon_path = ""
    for kind, endpoint, query, pattern in ART_KINDS:
        base = pattern.format(appid=appid_u)
        have = existing_art(grid, base)
        if have and kind == "icon":
            icon_path = have  # keep the old icon in the vdf if a re-fetch fails
        if have and not artwork_force:
            continue
        try:
            url = sgdb_asset_url(gid, kind, endpoint, query)
            if not url:
                print(f"  WARNING: {name}: SteamGridDB has no {kind} asset")
                continue
            ext = os.path.splitext(urllib.parse.urlparse(url).path)[1] or ".png"
            dest = os.path.join(grid, base + ext)
            download(url, dest)
            if kind == "icon":
                icon_path = dest
        except Exception as e:
            print(f"  WARNING: {name}: failed to fetch {kind}: {e}")
    return icon_path


# ----------------------------------------------------------------------------

games = []
for entry in sorted(os.listdir(romdir)):
    folder = os.path.join(romdir, entry)
    if os.path.isdir(folder):
        xci = pick_xci(folder)
        if xci:
            games.append((entry, xci))

if not games:
    sys.exit(f"No .xci games found under {romdir}")


def shortcut_appid_unsigned(exe, name):
    """Steam's appid for a non-Steam shortcut. grid/ artwork files are named
    after this unsigned form; the vdf field stores it as a signed int32."""
    return (binascii.crc32((exe + name).encode("utf-8")) & 0xFFFFFFFF) | 0x80000000


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
        appid_u = shortcut_appid_unsigned(launcher, name)
        icon = fetch_artwork(cfg, appid_u, name, os.path.join(romdir, name))
        entry = {
            "appid": appid_u - 0x100000000,  # signed int32 for VDF
            "appname": name,
            "exe": f'"{launcher}"',
            "StartDir": f'"{launcher_dir}"',
            "icon": icon,
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
