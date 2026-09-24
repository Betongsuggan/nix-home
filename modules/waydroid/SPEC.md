# Waydroid

Runs a full Android container on top of a Wayland compositor. The reason it exists in this
config is DRM: streaming services expose offline downloads only in their mobile apps, and
Linux browsers get Widevine L3 with no download support at all. Running the Android app is
the only way to put a Netflix episode on this laptop's disk.

`drmSetup` adds the pieces Waydroid can't ship itself — the Widevine CDM and the libndk ARM
translation layer.

## Usage

```nix
waydroid = {
  enable = true;
  drmSetup = true;
};
```

Start Android on demand:

```bash
waydroid-up      # starts the container if needed, waits for the session, opens the UI
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Waydroid Android container |
| startOnBoot | bool | false | Start `waydroid-container` at boot instead of on demand |
| drmSetup | bool | false | Install the `waydroid-drm-setup` helper (Widevine CDM + libndk ARM translation) |

## What actually works

| Service | Status |
|---------|--------|
| Netflix | Playback works; **SD only** (~480–540p). Waydroid is structurally Widevine L3 — a container has no TEE, so L1 is impossible (upstream `waydroid#1408`). Offline downloads are expected to work (L3 supports persistent licences) but are unverified — treat the download arrow as the go/no-go gate. |
| Disney+ | Hard block. Requires Widevine L1 for playback at all; sideloading yields error 32 / "device not trusted". |
| HBO Max | Hard block. |

For Disney+ and Max, use a phone or tablet.

## Setup

`enable = true` adds `psi=1` to the kernel command line, so the **first activation needs a
reboot**, not just `nixos-rebuild switch`. Verify with `grep psi=1 /proc/cmdline`.

Everything below mutates `/var/lib/waydroid`, which lives outside the Nix store and
survives rebuilds.

1. Pull the Android 13 image **with** Google apps — the vanilla image can't install Netflix:

   ```bash
   sudo waydroid init -s GAPPS -f
   waydroid-up
   ```

2. Sign into Google inside the container. It will report the device as not Play Protect
   certified; read its ID and register it at <https://www.google.com/android/uncertified>
   using the same account:

   ```bash
   sudo waydroid shell -- sh -c \
     "sqlite3 /data/data/*/*/gservices.db 'select value from main where name = \"android_id\";'"
   ```

   Wait 10–20 minutes, then `waydroid session stop`, clear data for Play Services and the
   Play Store, and restart the session. Netflix is not installable until this lands.

3. Install the **phone** Netflix build from the Play Store. The Android TV build reports
   "not compatible".

4. **Go/no-go:** open a series and check that a download arrow appears and that the
   download completes. If there is no arrow, stop — no further configuration produces one.

5. Add the DRM blobs and re-test playback:

   ```bash
   sudo waydroid-drm-setup
   ```

   libndk, not libhoudini — the latter is Intel's translator and behaves poorly on AMD.

6. Only if playback fails, pin the GPU backend by editing
   `/var/lib/waydroid/waydroid_base.prop` directly:

   ```
   ro.hardware.gralloc=gbm
   ro.hardware.egl=mesa
   ro.hardware.vulkan=radeon
   ```

   Edit the file rather than calling `waydroid prop set` from a post-start unit, which
   races into a SwiftShader fallback after reboots.

## Notes

- Requires a Wayland compositor (Hyprland, Sway, niri).
- The container does **not** start at boot by default. It is a full Android userspace and
  is useless without an open session, so `startOnBoot` defaults to `false` and
  `waydroid-up` brings it up when wanted. The upstream NixOS module pins the unit to
  `multi-user.target`; this module overrides that with `mkForce [ ]`.
- `waydroid session start` fails outright against a stopped container rather than
  activating it, which is why `waydroid-up` exists: it starts the unit (prompting through
  polkit), polls `waydroid status` until the session reports `RUNNING`, then opens the UI.
  Calling `show-full-ui` before the session is ready silently does nothing.
- **Re-run `sudo waydroid-drm-setup` after every `waydroid upgrade`** — upgrading replaces
  `system.img`/`vendor.img` and discards the blobs in `/var/lib/waydroid/overlay/vendor/`.
- Uses `pkgs.waydroid-nftables`, not `pkgs.waydroid`: kernel 6.16.9 dropped the `ip_tables`
  module the stock package depends on, so on 6.18 the container service fails to start.
  The upstream NixOS module only auto-selects the nftables build when
  `networking.nftables.enable` is set, which is unrelated to the kernel situation.
- Audio needs `services.pipewire.pulse.enable` — Waydroid speaks the PulseAudio protocol
  and has no native PipeWire backend. The `audio` module already provides it.
- **Do not install Magisk.** Netflix root-detects, and Waydroid can never pass Play
  Integrity anyway (no verified boot). Netflix gates on Widevine plus the device
  registration in step 2, not on integrity attestation.
- The GAPPS image is ~2–3 GB before any downloaded episodes.
- `waydroid-drm-setup` keeps a checkout of `casualsnek/waydroid_script` in
  `/var/lib/waydroid-script` and fetches the proprietary blobs from the network at run
  time; they cannot be expressed as Nix derivations.
