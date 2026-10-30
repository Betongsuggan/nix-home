"""Tell Steam when a game on Wine's Wayland driver is focused.

Steam (an XWayland client) picks the Steam Input layout from the focused X
window: the game's layout when it belongs to a game Steam launched, the
desktop layout otherwise. A window on Wine's Wayland driver isn't in the X
world, so Steam falls back to the desktop layout and stays there. This keeps
one invisible 1x1 X window and, whenever Hyprland focuses a window whose
process Steam launched (SteamAppId in its environment), tags that window with
the game's appid and pid and makes it X's active, focused window. Hyprland's
own focus (keyboard, pointer) is untouched. Focus moving to an X window
updates X focus by itself, so nothing is needed for those."""
import json
import os
import socket
import subprocess

from Xlib import X, Xatom, display

d = display.Display()
root = d.screen().root
atom = d.intern_atom
win = root.create_window(-10, -10, 1, 1, 0, X.CopyFromParent, override_redirect=True)
win.map()
d.sync()


def steam_appid(pid):
    try:
        with open(f"/proc/{pid}/environ", "rb") as f:
            env = dict(v.split(b"=", 1) for v in f.read().split(b"\0") if b"=" in v)
        return int(env[b"SteamAppId"])
    except (OSError, KeyError, ValueError):
        return 0


def focus(pid, appid):
    win.change_property(atom("STEAM_GAME"), Xatom.CARDINAL, 32, [appid])
    win.change_property(atom("_NET_WM_PID"), Xatom.CARDINAL, 32, [pid])
    win.set_wm_class(f"steam_app_{appid}", f"steam_app_{appid}")
    root.change_property(atom("_NET_ACTIVE_WINDOW"), Xatom.WINDOW, 32, [win.id])
    win.set_input_focus(X.RevertToPointerRoot, X.CurrentTime)
    d.sync()


sock = socket.socket(socket.AF_UNIX)
sock.connect(
    f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock"
)
buf = b""
while chunk := sock.recv(4096):
    buf += chunk
    *lines, buf = buf.split(b"\n")
    if not any(line.startswith(b"activewindow>>") for line in lines):
        continue
    active = json.loads(subprocess.check_output(["hyprctl", "-j", "activewindow"]))
    # Only native Wayland windows; X windows already carry their own focus
    if active.get("xwayland", True):
        continue
    appid = steam_appid(active["pid"])
    if appid:
        focus(active["pid"], appid)
