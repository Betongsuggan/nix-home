# Media

Local media playback and offline downloading of DRM-free video. Installs `mpv` as the
player and, by default, `yt-dlp` and `ffmpeg` for pulling episodes onto disk ahead of time (trains,
flights, anywhere without network).

This module deliberately covers only DRM-free sources. Services that require Widevine
(Netflix, Disney+, HBO Max, TV4 Play, Viaplay) cannot be downloaded this way — see
`modules/waydroid/SPEC.md` for the Android-container route.

## Usage

```nix
media.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable media playback and offline downloading |
| downloader | bool | true | Install yt-dlp (plus ffmpeg, which it needs to mux streams) for downloading DRM-free video |

## Notes

- Works out of the box for SVT Play, NRK TV, DR TV, YouTube and the rest of yt-dlp's
  extractor list. **Does not** work for TV4 Play or Viaplay — both are Widevine-protected.
- Download a full series with subtitles, capped at 720p to save disk:

  ```bash
  yt-dlp -f "bv*[height<=720]+ba/b[height<=720]" \
         --write-subs --sub-langs sv,en --embed-subs \
         -o "%(series)s/S%(season_number)02dE%(episode_number)02d - %(title)s.%(ext)s" \
         "<series or episode URL>"
  ```

  Add `--download-archive seen.txt` when re-running against a series URL so already
  fetched episodes are skipped.
- `mpv` uses VA-API hardware decoding on amdgpu automatically. `vlc` is also present via
  the `general` module; either plays the results.
- Verify a download really is offline-playable with `nmcli networking off` before leaving.
