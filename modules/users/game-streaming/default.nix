{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.game-streaming;

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

  # Generate Moonlight config file content (Qt INI format)
  moonlightConfig = ''
    [General]
    SER_WIDTH=${toString cfg.client.resolution.width}
    SER_HEIGHT=${toString cfg.client.resolution.height}
    SER_FPS=${toString cfg.client.fps}
    SER_BITRATE=${toString cfg.client.bitrate}
    SER_VIDEOCFG=${toString (codecValue.${cfg.client.codec})}
    SER_VSYNC=${if cfg.client.vsync then "true" else "false"}
    SER_HDR=${if cfg.client.hdr then "true" else "false"}
    SER_VIDEODEC=${toString (decoderValue.${cfg.client.decoder})}
    SER_FRAMEPACING=${if cfg.client.framePacing then "true" else "false"}
    SER_AUTOADJUSTBITRATE=${if cfg.client.autoBitrate then "true" else "false"}
    SER_SHOWPERFOVERLAY=${if cfg.client.showPerfOverlay then "true" else "false"}
  '';

in {
  options.game-streaming = {
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
        type = types.enum [ "auto" "h264" "hevc" "av1" ];
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
        type = types.enum [ "auto" "hardware" "software" ];
        default = "auto";
        description = "Video decoder selection (auto recommended for Intel/AMD laptops)";
      };

      framePacing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable frame pacing for smoother playback";
      };

      autoBitrate = mkOption {
        type = types.bool;
        default = false;
        description = "Auto-adjust bitrate based on network (disable for consistent LAN quality)";
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

    # Write Moonlight configuration
    # Path: ~/.config/Moonlight Game Streaming Project/Moonlight.conf
    xdg.configFile."Moonlight Game Streaming Project/Moonlight.conf" = {
      text = moonlightConfig;
    };
  };
}