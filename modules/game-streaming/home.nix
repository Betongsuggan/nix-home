{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.game-streaming;

  # Moonlight codec enum values (from streamingpreferences.h)
  # VCC_AUTO = 0, VCC_FORCE_H264 = 1, VCC_FORCE_HEVC = 2, VCC_FORCE_AV1 = 4
  codecValue = {
    "auto" = 0;
    "h264" = 1;
    "hevc" = 2;
    "av1" = 4;
  };

  # Video decoder enum values
  # VDS_AUTO = 0, VDS_FORCE_HARDWARE = 1, VDS_FORCE_SOFTWARE = 2
  decoderValue = {
    "auto" = 0;
    "hardware" = 1;
    "software" = 2;
  };

  # Moonlight's settings keys (StreamingPreferences in moonlight-qt). The
  # names are the lower-case ones Moonlight itself writes; it ignores
  # anything else in the section.
  moonlightSettings = {
    width = cfg.client.resolution.width;
    height = cfg.client.resolution.height;
    fps = cfg.client.fps;
    bitrate = cfg.client.bitrate;
    videocfg = codecValue.${cfg.client.codec};
    vsync = cfg.client.vsync;
    hdr = cfg.client.hdr;
    videodec = decoderValue.${cfg.client.decoder};
    framepacing = cfg.client.framePacing;
    showperfoverlay = cfg.client.showPerfOverlay;
  };

  # Earlier versions of this module wrote these names, which Moonlight never
  # read; drop them from existing configs.
  staleKeys = [
    "SER_WIDTH"
    "SER_HEIGHT"
    "SER_FPS"
    "SER_BITRATE"
    "SER_VIDEOCFG"
    "SER_VSYNC"
    "SER_HDR"
    "SER_VIDEODEC"
    "SER_FRAMEPACING"
    "SER_AUTOADJUSTBITRATE"
    "SER_SHOWPERFOVERLAY"
  ];

  moonlightConfig = lib.generators.toINI { } { General = moonlightSettings; };

in
{
  options.my.game-streaming = {
    client = {
      enable = mkEnableOption "Enable Moonlight game streaming client with optimized settings";

      resolution = {
        width = mkOption {
          type = types.int;
          default = 1920;
          description = "Stream resolution width";
        };
        height = mkOption {
          type = types.int;
          default = 1080;
          description = "Stream resolution height";
        };
      };

      fps = mkOption {
        type = types.int;
        default = 120;
        description = "Target frame rate for streaming";
      };

      bitrate = mkOption {
        type = types.int;
        default = 100000;
        description = "Bitrate in Kbps (100000 = 100 Mbps, good for LAN gaming)";
      };

      codec = mkOption {
        type = types.enum [
          "auto"
          "h264"
          "hevc"
          "av1"
        ];
        default = "auto";
        description = ''
          Video codec preference.
          - auto: Let Moonlight negotiate best codec (recommended)
          - h264: Force H.264 (most compatible)
          - hevc: Force HEVC/H.265 (better quality, required for HDR)
          - av1: Force AV1 (best quality, requires modern GPU)
        '';
      };

      vsync = mkOption {
        type = types.bool;
        default = false;
        description = "Enable V-Sync (adds latency, disable for gaming)";
      };

      hdr = mkOption {
        type = types.bool;
        default = true;
        description = "Enable HDR streaming when available";
      };

      decoder = mkOption {
        type = types.enum [
          "auto"
          "hardware"
          "software"
        ];
        default = "auto";
        description = "Video decoder selection (auto recommended for Intel/AMD laptops)";
      };

      framePacing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable frame pacing for smoother playback";
      };

      showPerfOverlay = mkOption {
        type = types.bool;
        default = false;
        description = "Show performance overlay by default";
      };
    };
  };

  config = mkIf cfg.client.enable {
    home.packages = [ pkgs.moonlight-qt ];

    # Moonlight keeps pairing data and its own settings in the same file, so it
    # must stay writable: merge the declared [General] keys into it on every
    # activation instead of symlinking a read-only copy from the store.
    home.activation.moonlightConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      conf="${config.xdg.configHome}/Moonlight Game Streaming Project/Moonlight.conf"
      run mkdir -p "$(dirname "$conf")"
      if [ -L "$conf" ]; then run rm "$conf"; fi
      for key in ${toString staleKeys}; do
        run ${pkgs.crudini}/bin/crudini --ini-options=nospace --del "$conf" General "$key" 2>/dev/null || true
      done
      run ${pkgs.crudini}/bin/crudini --ini-options=nospace --merge "$conf" \
        < ${pkgs.writeText "moonlight-general.conf" moonlightConfig}
    '';
  };
}
