import os
import re
import select
import struct
import subprocess
import time

PAD_NAME = "Sunshine X-Box One (virtual) pad"
BTN_SELECT, BTN_START = 314, 315
HOLD_SECONDS = @holdSeconds@
EVENT_FORMAT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)


def find_pad():
    try:
        blocks = open("/proc/bus/input/devices").read().split("\n\n")
    except OSError:
        return None
    for block in blocks:
        if PAD_NAME in block:
            m = re.search(r"event(\d+)", block)
            if m:
                return "/dev/input/event" + m.group(1)
    return None


def hyprland_env():
    env = dict(os.environ)
    hypr_dir = os.path.join(env.get("XDG_RUNTIME_DIR", ""), "hypr")
    try:
        sigs = sorted(
            os.listdir(hypr_dir),
            key=lambda s: os.path.getmtime(os.path.join(hypr_dir, s)),
            reverse=True,
        )
        if sigs:
            env["HYPRLAND_INSTANCE_SIGNATURE"] = sigs[0]
    except OSError:
        pass
    return env


def quit_game():
    env = hyprland_env()
    subprocess.run(
        ["@hyprctl@", "dispatch", "closewindow", "class:Ryujinx"],
        env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    for _ in range(10):
        alive = subprocess.run(
            ["@pgrep@", "-x", "Ryujinx"],
            stdout=subprocess.DEVNULL,
        ).returncode == 0
        if not alive:
            return
        time.sleep(0.5)
    subprocess.run(["@pkill@", "-TERM", "-x", "Ryujinx"])


while True:
    dev = find_pad()
    if dev is None:
        time.sleep(2)
        continue
    try:
        fd = os.open(dev, os.O_RDONLY)
    except OSError:
        time.sleep(2)
        continue
    down = {}
    fired = False
    try:
        while True:
            ready, _, _ = select.select([fd], [], [], 0.2)
            if ready:
                data = os.read(fd, EVENT_SIZE)
                if len(data) < EVENT_SIZE:
                    break
                _, _, etype, code, value = struct.unpack(EVENT_FORMAT, data)
                if etype == 1 and code in (BTN_SELECT, BTN_START):
                    if value == 1:
                        down[code] = time.monotonic()
                    elif value == 0:
                        down.pop(code, None)
                        fired = False
            if (
                not fired
                and len(down) == 2
                and time.monotonic() - max(down.values()) >= HOLD_SECONDS
            ):
                fired = True
                quit_game()
    except OSError:
        pass  # pad unplugged (Moonlight disconnect) — rediscover
    finally:
        os.close(fd)
