{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.media;
in
{
  options.media = {
    enable = mkEnableOption "Enable media playback and offline downloading";

    downloader = mkOption {
      type = types.bool;
      default = true;
      description = "Install yt-dlp for downloading DRM-free video for offline viewing";
    };
  };

  config = mkIf cfg.enable {
    # ffmpeg is not optional in practice: yt-dlp needs it to mux the separate
    # video/audio streams that DASH/HLS sources serve, and to embed subtitles.
    home.packages =
      with pkgs;
      [ mpv ]
      ++ optionals cfg.downloader [
        yt-dlp
        ffmpeg
      ];
  };
}
