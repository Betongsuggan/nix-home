#!/usr/bin/env python3
"""Upsert Steam non-Steam-game shortcuts for emulated games, directly into
shortcuts.vdf (no Steam ROM Manager / Electron needed).

Driven by a JSON manifest (path in $EMU_MANIFEST) generated from Nix:

    {
      "hyprctl": "/nix/store/.../bin/hyprctl",
      "artworkKeyFile": "/run/secrets/steamgriddb-api-key",   # "" = no artwork
      "systems": {
        "snes": {
          "romDir": "/home/gamer/emulation/roms/snes",
          "extensions": [".sfc", ".smc", ".zip"],
          "layout": "flat",                 # or "folder" (one dir per game)
          "command": ["/nix/store/.../bin/retroarch", "-L", ".../snes9x_libretro.so"],
          "windowClass": "retroarch",       # Hyprland class for the fullscreen poll
          "tag": "SNES",                    # Steam collection
          "launcherDir": "/home/gamer/.local/share/emulation-shortcuts/snes"
        },
        ...
      }
    }

Steam mangles quoting of space-filled paths in a shortcut's LaunchOptions, so
instead of passing the ROM path as an argument we generate a tiny per-game
launcher script (paths quoted internally) and point the shortcut's exe at it,
with empty LaunchOptions. Idempotent: existing entries are matched by exe path
(not app name — the same game can exist on two systems), and entries whose
launcher lives under a managed launcherDir but wasn't produced this run are
pruned (ROM deleted/renamed). Pruning is skipped for any system that yielded
zero games, so an unreachable/empty ROM mount never wipes that system's tiles.

If artworkKeyFile points at a readable SteamGridDB API key, artwork
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

with open(os.environ["EMU_MANIFEST"]) as f:
    manifest = json.load(f)

systems = manifest["systems"]
hyprctl = manifest.get("hyprctl", "hyprctl")
sgdb_key_file = manifest.get("artworkKeyFile", "")
artwork_force = os.environ.get("EMU_ARTWORK_FORCE", "") == "1"
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


def find_flat_games(romdir, extensions):
    """One game per ROM file matching the extensions (case-insensitive).
    Multi-file games collapse to one entry: files whose stem extends an .m3u
    playlist's stem are skipped (multi-disc images), and among same-stem
    siblings .m3u beats .cue beats .chd (PSX cue+chd double dumps)."""
    exts = tuple(e.lower() for e in extensions)
    files = [
        f for f in sorted(os.listdir(romdir))
        if os.path.isfile(os.path.join(romdir, f))
        and os.path.splitext(f)[1].lower() in exts
    ]
    m3u_stems = [os.path.splitext(f)[0] for f in files if f.lower().endswith(".m3u")]
    priority = {".m3u": 0, ".cue": 1, ".chd": 2}
    best = {}
    for f in files:
        stem, ext = os.path.splitext(f)
        ext = ext.lower()
        if ext != ".m3u" and any(stem.startswith(m) for m in m3u_stems):
            continue  # individual disc of a playlist-covered game
        rank = priority.get(ext, 9)
        if stem not in best or rank < best[stem][0]:
            best[stem] = (rank, os.path.join(romdir, f))
    return [(stem, path) for stem, (_, path) in sorted(best.items())]


def find_folder_games(romdir, extensions):
    """One game per directory (Switch-style layout): the entry is named after
    the folder and launches the base ROM inside it, skipping update/DLC files
    marked (UPD)/(DLC)."""
    exts = tuple(e.lower() for e in extensions)
    games = []
    for entry in sorted(os.listdir(romdir)):
        folder = os.path.join(romdir, entry)
        if not os.path.isdir(folder):
            continue
        matches = sorted(
            p for p in glob.glob(os.path.join(folder, "*"))
            if os.path.splitext(p)[1].lower() in exts
        )
        base = [
            p for p in matches
            if "(UPD)" not in os.path.basename(p) and "(DLC)" not in os.path.basename(p)
        ]
        rom = (base or matches)[0] if matches else None
        if rom:
            games.append((entry, rom))
    return games


def sanitize(name):
    return "".join(c if (c.isalnum() or c in "-_.") else "_" for c in name)


def write_launcher(launcher_dir, name, rom, command, window_class):
    """Write a shell launcher: (1) fullscreen the emulator window on the
    streamed monitor once it appears — the `fullscreen` window rule isn't valid
    in Hyprland 0.55, so we do it at runtime with hyprctl; (2) run the game with
    every path quoted internally so Steam never has to parse it. Returns the
    launcher path."""
    path = os.path.join(launcher_dir, sanitize(name) + ".sh")
    cmd = " ".join('"%s"' % c for c in command)
    script = (
        "#!/bin/sh\n"
        "# Bring the emulator fullscreen on the SUNSHINE monitor once its window\n"
        "# appears (over Big Picture); otherwise it renders behind Steam and the\n"
        "# stream shows no video.\n"
        "(\n"
        "  n=0\n"
        "  while [ \"$n\" -lt 40 ]; do\n"
        "    if \"%s\" clients 2>/dev/null | grep -q 'class: %s'; then\n"
        "      \"%s\" dispatch focuswindow 'class:%s' >/dev/null 2>&1\n"
        "      \"%s\" dispatch fullscreen 0 >/dev/null 2>&1\n"
        "      break\n"
        "    fi\n"
        "    n=$((n+1)); sleep 0.5\n"
        "  done\n"
        ") &\n"
        "exec %s \"%s\"\n"
    ) % (hyprctl, window_class, hyprctl, window_class, hyprctl, cmd, rom)
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
SGDB_UA = "emulation-add-shortcuts/1.0 (+https://github.com/Betongsuggan/nix-home)"

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


def sgdb_game_id(name, override_file):
    """SGDB game id for a game: an override file (`.sgdbid` in the game folder
    for folder layout, `<RomStem>.sgdbid` next to the ROM for flat layout) wins
    — the escape hatch for bad name matches — otherwise first autocomplete hit.
    Logs the matched title so silent mismatches are visible in the output."""
    if name in _sgdb_id_cache:
        return _sgdb_id_cache[name]
    gid = None
    if override_file and os.path.exists(override_file):
        with open(override_file) as f:
            gid = int(f.read().strip())
        print(f"  {name}: using SteamGridDB id {gid} from {os.path.basename(override_file)}")
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


def fetch_artwork(cfg, appid_u, name, override_file):
    """Fetch all art kinds for one game into cfg/grid/. Returns the icon path
    ('' if unavailable). Existing files are kept unless EMU_ARTWORK_FORCE=1.
    Never raises — shortcuts must be written even when artwork fails."""
    if not sgdb_key:
        return ""
    grid = os.path.join(cfg, "grid")
    os.makedirs(grid, exist_ok=True)
    try:
        gid = sgdb_game_id(name, override_file)
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


# --- Game discovery + launcher generation (once, shared by all config dirs) --

entries = []       # dicts: system, name, rom, launcher, launcher_dir, tag, override
prune_dirs = set()  # launcherDirs safe to prune (their system yielded >= 1 game)

for sysname in sorted(systems):
    s = systems[sysname]
    romdir = os.path.expanduser(s["romDir"])
    launcher_dir = os.path.expanduser(s["launcherDir"])
    if not os.path.isdir(romdir):
        print(f"NOTE: {sysname}: ROM dir {romdir} does not exist — skipped (tiles kept).")
        continue
    if s["layout"] == "folder":
        games = find_folder_games(romdir, s["extensions"])
    else:
        games = find_flat_games(romdir, s["extensions"])
    if not games:
        # Could be genuinely empty or an unreachable CIFS automount showing an
        # empty dir — either way, don't touch this system's existing tiles.
        print(f"NOTE: {sysname}: no ROMs matching {s['extensions']} in {romdir} — skipped (tiles kept).")
        continue
    os.makedirs(launcher_dir, exist_ok=True)
    prune_dirs.add(os.path.realpath(launcher_dir))
    for name, rom in games:
        launcher = write_launcher(launcher_dir, name, rom, s["command"], s["windowClass"])
        if s["layout"] == "folder":
            override = os.path.join(os.path.dirname(rom), ".sgdbid")
        else:
            override = os.path.join(romdir, os.path.splitext(os.path.basename(rom))[0] + ".sgdbid")
        entries.append({
            "system": sysname, "name": name, "rom": rom, "launcher": launcher,
            "launcher_dir": launcher_dir, "tag": s["tag"], "override": override,
        })

if not entries:
    sys.exit("No games found for any system — nothing written (existing tiles untouched).")

produced = {e["launcher"] for e in entries}

# Remove orphaned launcher scripts (ROM deleted/renamed) in pruned dirs.
for d in prune_dirs:
    for stale in glob.glob(os.path.join(d, "*.sh")):
        if stale not in produced:
            os.unlink(stale)
            print(f"Pruned stale launcher {stale}")


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
    # Keyed by exe (not appname): the same title can exist on two systems.
    by_exe = {
        (v.get("exe") or v.get("Exe") or "").strip('"'): k
        for k, v in shortcuts.items()
    }

    for e in entries:
        appid_u = shortcut_appid_unsigned(e["launcher"], e["name"])
        icon = fetch_artwork(cfg, appid_u, e["name"], e["override"])
        old = shortcuts.get(by_exe.get(e["launcher"], ""), {})
        entry = {
            "appid": appid_u - 0x100000000,  # signed int32 for VDF
            "appname": e["name"],
            "exe": f'"{e["launcher"]}"',
            "StartDir": f'"{e["launcher_dir"]}"',
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
            # Preserved so Big Picture's "recent" ordering survives re-runs.
            "LastPlayTime": old.get("LastPlayTime", 0),
            "FlatpakAppID": "",
            "tags": {"0": e["tag"]},
        }
        if e["launcher"] in by_exe:
            key = by_exe[e["launcher"]]
        else:
            nums = [int(k) for k in shortcuts.keys() if k.isdigit()]
            key = str(max(nums) + 1) if nums else "0"
            by_exe[e["launcher"]] = key
        shortcuts[key] = entry

    # Prune managed entries whose launcher wasn't produced this run. Scoped to
    # launcherDirs of systems that yielded games, so BoilR/manual shortcuts and
    # skipped systems are never touched.
    pruned = []
    for key in list(shortcuts.keys()):
        v = shortcuts[key]
        exe = (v.get("exe") or v.get("Exe") or "").strip('"')
        if not exe:
            continue
        if os.path.realpath(os.path.dirname(exe)) in prune_dirs and exe not in produced:
            pruned.append(v.get("appname") or v.get("AppName") or exe)
            del shortcuts[key]
    if pruned:
        # Renumber compactly — Steam expects dense numeric keys.
        data["shortcuts"] = {
            str(i): shortcuts[k]
            for i, k in enumerate(sorted(shortcuts, key=lambda k: int(k) if k.isdigit() else 0))
        }
        print(f"Pruned {len(pruned)} stale shortcut(s): {', '.join(pruned)}")

    with open(path, "wb") as f:
        vdf.binary_dump(data, f)
    print(f"Wrote {len(entries)} shortcut(s) to {path}")

by_system = {}
for e in entries:
    by_system.setdefault(e["system"], []).append(e)
for sysname in sorted(by_system):
    print(f"{sysname}:")
    for e in by_system[sysname]:
        print(f"  - {e['name']}  ->  {os.path.basename(e['rom'])}")
print("Done. Restart Steam (reconnect the Moonlight 'Steam Gaming' app) to see them.")
