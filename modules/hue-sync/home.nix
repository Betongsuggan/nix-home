# Philips Hue screen sync: HyperHDR grabs the screen through the PipeWire
# portal and streams edge colours to the Hue bridge over the Entertainment
# API (CLIP v2). Everything but the two bridge keys is declared here and
# written into HyperHDR's settings database at every service start.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.hue-sync;

  # Named screen regions, as fractions of the captured output in HyperHDR's
  # LED-layout terms: h runs 0 (left) .. 1 (right), v runs 0 (top) .. 1 (bottom).
  regions = {
    left = {
      hmin = 0.0;
      hmax = 0.15;
      vmin = 0.0;
      vmax = 1.0;
    };
    right = {
      hmin = 0.85;
      hmax = 1.0;
      vmin = 0.0;
      vmax = 1.0;
    };
    top = {
      hmin = 0.0;
      hmax = 1.0;
      vmin = 0.0;
      vmax = 0.15;
    };
    bottom = {
      hmin = 0.0;
      hmax = 1.0;
      vmin = 0.85;
      vmax = 1.0;
    };
    top-left = {
      hmin = 0.0;
      hmax = 0.3;
      vmin = 0.0;
      vmax = 0.3;
    };
    top-right = {
      hmin = 0.7;
      hmax = 1.0;
      vmin = 0.0;
      vmax = 0.3;
    };
    bottom-left = {
      hmin = 0.0;
      hmax = 0.3;
      vmin = 0.7;
      vmax = 1.0;
    };
    bottom-right = {
      hmin = 0.7;
      hmax = 1.0;
      vmin = 0.7;
      vmax = 1.0;
    };
    center = {
      hmin = 0.3;
      hmax = 0.7;
      vmin = 0.3;
      vmax = 0.7;
    };
    full = {
      hmin = 0.0;
      hmax = 1.0;
      vmin = 0.0;
      vmax = 1.0;
    };
  };

  fraction = types.numbers.between 0 1;
  region = types.submodule {
    options = genAttrs [ "hmin" "hmax" "vmin" "vmax" ] (
      n:
      mkOption {
        type = fraction;
        description = "Edge of the region (${n}), as a fraction of the screen.";
      }
    );
  };
  toRegion = c: if isString c then regions.${c} else c;

  # HyperHDR keeps these settings per daemon (hyperhdr_instance NULL); every
  # other type belongs to LED instance 0 (DBManager/SettingsTable.cpp).
  globalTypes = [
    "general"
    "logger"
    "systemGrabber"
    "videoGrabber"
    "webConfig"
    "jsonServer"
    "protoServer"
    "flatbufServer"
    "network"
    "forwarder"
    "soundEffect"
    "videoDetection"
    "mqtt"
    "automaticToneMapping"
  ];

  # One object per HyperHDR settings type (sources/base/schema/*.json).
  # Types left out keep HyperHDR's own defaults.
  generated = {
    general = {
      name = "hue-sync";
      showOptHelp = false;
      version = 4; # current DB layout: skips the v20 migrations
      disableOnLocked = false;
      disableLedsStartup = false;
    };
    device = {
      type = "philipshue";
      colorOrder = "rgb";
      refreshTime = 0;
      hardwareLedCount = length cfg.channels;
      output = cfg.bridge.address;
      # username/clientkey are filled in from the key files at service start
      username = "";
      clientkey = "";
      useEntertainmentAPI = true;
      useEntertainmentAPIV2 = true;
      entertainmentConfigurationId = cfg.entertainmentArea;
      brightnessFactor = cfg.brightness;
      restoreOriginalState = cfg.restoreLightsOnStop;
      switchOffOnBlack = false;
      candyGamma = false;
      maxRetry = 60;
      handshakeTimeoutMin = 600;
      handshakeTimeoutMax = 1000;
      verbose = false;
    };
    # LED i feeds entertainment channel i (channel_id order from the bridge)
    leds = map (c: toRegion c // { group = 0; }) cfg.channels;
    # Routes the system (screen) grabber into instance 0; off by default
    systemControl = {
      systemInstanceEnable = true;
      systemInstancePriority = 245;
      cecControl = false;
    };
    systemGrabber = {
      device = "auto";
      videoMode = cfg.capture.width;
      fps = cfg.capture.fps;
      hdrToneMapping = cfg.capture.hdrToneMapping;
      hardware = true;
      monitor_nits = 200;
      reorder_displays = 0;
      cropLeft = 0;
      cropRight = 0;
      cropTop = 0;
      cropBottom = 0;
      signalDetection = false;
      redSignalThreshold = 5;
      greenSignalThreshold = 5;
      blueSignalThreshold = 5;
      noSignalCounterThreshold = 200;
      sDVOffsetMin = 0.25;
      sDVOffsetMax = 0.75;
      sDHOffsetMin = 0.25;
      sDHOffsetMax = 0.75;
    };
    # Hue lamps cover big screen regions: sample every other pixel (what
    # HyperHDR switches on by itself, with a warning, for areas this size).
    # The channel adjustment is HyperHDR's default; override via
    # extraSettings.color for calibration.
    color = {
      imageToLedMappingType = "advanced";
      sparse_processing = true;
      channelAdjustment = [
        {
          id = "default";
          leds = "*";
          classic_config = false;
          white = [
            255
            255
            255
          ];
          red = [
            255
            0
            0
          ];
          green = [
            0
            255
            0
          ];
          blue = [
            0
            0
            255
          ];
          cyan = [
            0
            255
            255
          ];
          magenta = [
            255
            0
            255
          ];
          yellow = [
            255
            255
            0
          ];
          backlightThreshold = 1;
          backlightColored = true;
          brightness = 100;
          brightnessCompensation = 0;
          gammaRed = 1.5;
          gammaGreen = 1.5;
          gammaBlue = 1.5;
          temperatureRed = 255;
          temperatureGreen = 255;
          temperatureBlue = 255;
          saturationGain = 1.0;
          luminanceGain = 1.0;
        }
      ];
    };
    # No rainbow swirl on the lights at every service start
    foregroundEffect = {
      enable = false;
      type = "effect";
      color = [
        0
        0
        0
      ];
      effect = "Rainbow swirl fast";
      duration_ms = 3000;
    };
    webConfig = {
      document_root = "";
      port = cfg.webUi.port;
      sslPort = cfg.webUi.port + 2;
      crtPath = "";
      keyPath = "";
      keyPassPhrase = "";
    };
  };

  settingsJson = pkgs.writeText "hue-sync-settings.json" (
    builtins.toJSON (recursiveUpdate generated cfg.extraSettings)
  );

  dbFile = "${cfg.dataDir}/db/hyperhdr.db";

  # Writes the declared settings into HyperHDR's SQLite settings table
  # (type, config, hyperhdr_instance, updated_at), replacing the managed
  # rows only. Everything else in the DB -- the portal restore token, the
  # web-UI password, settings types not declared here -- is left alone.
  applyConfig = pkgs.writeShellApplication {
    name = "hue-sync-apply-config";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.sqlite
    ];
    text = ''
      mkdir -p "$(dirname "${dbFile}")"
      now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      globals=" ${concatStringsSep " " globalTypes} "
      {
        echo "CREATE TABLE IF NOT EXISTS settings (type TEXT, config TEXT, hyperhdr_instance INTEGER, updated_at TEXT);"
        echo "BEGIN;"
        for type in $(jq -r 'keys[]' "${settingsJson}"); do
          config=$(jq -c --arg t "$type" '.[$t]' "${settingsJson}")
          if [ "$type" = device ]; then
            config=$(jq -c \
              --rawfile u "${cfg.bridge.appKeyFile}" \
              --rawfile c "${cfg.bridge.clientKeyFile}" \
              '.username = ($u | rtrimstr("\n")) | .clientkey = ($c | rtrimstr("\n"))' <<< "$config")
          fi
          escaped=''${config//\'/\'\'}
          case "$globals" in
            *" $type "*) instance=NULL; where="hyperhdr_instance IS NULL" ;;
            *) instance=0; where="hyperhdr_instance = 0" ;;
          esac
          echo "DELETE FROM settings WHERE type = '$type' AND $where;"
          echo "INSERT INTO settings (type, config, hyperhdr_instance, updated_at) VALUES ('$type', '$escaped', $instance, '$now');"
        done
        echo "COMMIT;"
      } | sqlite3 "${dbFile}"
    '';
  };

  # Bridge onboarding: find the bridge, register an app (link button), list
  # the entertainment areas with their channel positions. Prints what goes
  # into the vault and into the Nix config.
  setup = pkgs.writeShellApplication {
    name = "hue-sync-setup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      usage() {
        cat <<USAGE
      usage: hue-sync-setup discover
             hue-sync-setup pair  [bridge-address]
             hue-sync-setup areas [bridge-address] [app-key-file]

      discover  bridges on this network (Hue cloud discovery, needs internet)
      pair      press the bridge's link button first; registers this host and
                prints the app key and client key for the vault
      areas     lists the entertainment areas (set up in the Hue app) with
                their id and channel layout, for my.hue-sync.entertainmentArea
                and my.hue-sync.channels
      USAGE
      }

      cmd=''${1:-}
      bridge=''${2:-${cfg.bridge.address}}
      keyFile=''${3:-${cfg.bridge.appKeyFile}}

      case "$cmd" in
        discover)
          curl -fsS https://discovery.meethue.com/ \
            | jq -r '.[] | "\(.internalipaddress)\t\(.id)"' \
            || echo "No answer from Hue discovery; the bridge IP is also under Settings > My Hue system in the Hue app." >&2
          ;;
        pair)
          [ -n "$bridge" ] || { echo "no bridge address" >&2; exit 1; }
          echo "Press the link button on the bridge, then press Enter." >&2
          read -r _
          reply=$(curl -fsS -X POST "http://$bridge/api" \
            -d "{\"devicetype\":\"hyperhdr#$(hostname)\",\"generateclientkey\":true}")
          if jq -e '.[0].success' <<< "$reply" >/dev/null; then
            echo "Add to the vault (sops nix-vault/secrets/<host>.yaml):"
            jq -r '.[0].success | "hue:\n  app-key: \(.username)\n  client-key: \(.clientkey)"' <<< "$reply"
          else
            jq -r '.[0].error.description' <<< "$reply" >&2
            exit 1
          fi
          ;;
        areas)
          [ -n "$bridge" ] || { echo "no bridge address" >&2; exit 1; }
          [ -r "$keyFile" ] || { echo "app key file $keyFile is not readable" >&2; exit 1; }
          curl -fsSk "https://$bridge/clip/v2/resource/entertainment_configuration" \
            -H "hue-application-key: $(tr -d '\n' < "$keyFile")" \
            | jq -r '.data[] | "\(.metadata.name)\n  entertainmentArea = \"\(.id)\";\n  channels (in order; x: -1 left .. 1 right, y: -1 back .. 1 front, z: -1 floor .. 1 ceiling):"
                + (.channels | map("    channel \(.channel_id): x=\(.position.x) y=\(.position.y) z=\(.position.z)") | join("\n"))'
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    '';
  };
in
{
  options.my.hue-sync = {
    enable = mkEnableOption "Philips Hue screen sync through HyperHDR";

    package = mkOption {
      type = types.package;
      default = pkgs.hyperhdr;
      defaultText = literalExpression "pkgs.hyperhdr";
      description = "HyperHDR package (must be built with PipeWire support).";
    };

    bridge = {
      address = mkOption {
        type = types.str;
        example = "192.168.50.20";
        description = "IP or hostname of the Hue bridge, optionally with `:port`.";
      };

      appKeyFile = mkOption {
        # str, not path: a path would copy the key into the world-readable
        # nix store. Read at service start by hue-sync-apply-config.
        type = types.str;
        example = "/run/secrets/hue-app-key";
        description = ''
          File holding the bridge application key (the `username` the bridge
          hands out when pairing), readable by this user.
        '';
      };

      clientKeyFile = mkOption {
        type = types.str;
        example = "/run/secrets/hue-client-key";
        description = ''
          File holding the Entertainment API client key (the `clientkey` from
          pairing with `generateclientkey`), readable by this user.
        '';
      };
    };

    entertainmentArea = mkOption {
      type = types.str;
      example = "7b4e6d0a-3c21-4c9e-9f3a-1b0f2c8d5e61";
      description = ''
        Id of the entertainment area (set up in the Hue app) to stream to.
        `hue-sync-setup areas` lists them.
      '';
    };

    channels = mkOption {
      type = types.listOf (types.either (types.enum (attrNames regions)) region);
      default = [
        "left"
        "right"
      ];
      example = [
        "left"
        {
          hmin = 0.4;
          hmax = 0.6;
          vmin = 0.0;
          vmax = 0.1;
        }
        "right"
      ];
      description = ''
        One screen region per channel of the entertainment area, in channel
        order (`hue-sync-setup areas` prints the channels with their
        positions). A name picks a preset region (${concatStringsSep ", " (attrNames regions)});
        an attrset gives the edges as fractions of the screen.
      '';
    };

    capture = {
      fps = mkOption {
        type = types.ints.between 5 120;
        default = 25;
        description = "Screen capture rate. The bridge takes at most ~25 updates/s.";
      };

      width = mkOption {
        type = types.ints.between 196 1280;
        default = 512;
        description = "Width the captured frame is scaled down to before averaging.";
      };

      hdrToneMapping = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Tone-map the captured frame with HyperHDR's LUT. Off: Hyprland's
          screencopy already hands out SDR frames.
        '';
      };
    };

    brightness = mkOption {
      type = types.numbers.between 0.5 10.0;
      default = 1.0;
      description = "Brightness factor applied to the colours sent to the lights.";
    };

    restoreLightsOnStop = mkOption {
      type = types.bool;
      default = true;
      description = "Put the lights back to their previous state when the stream stops.";
    };

    webUi.port = mkOption {
      type = types.port;
      default = 8090;
      description = ''
        Port of HyperHDR's web UI on localhost (its TLS twin is `port + 2`).
        Handy for the live LED preview; changes made there to declared
        settings are overwritten at the next service start.
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "${config.xdg.dataHome}/hue-sync";
      defaultText = literalExpression ''"''${config.xdg.dataHome}/hue-sync"'';
      description = "HyperHDR's user data directory (settings DB, LUTs, logs).";
    };

    extraSettings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      example = literalExpression ''
        {
          smoothing.time_ms = 150;
          device.candyGamma = true;
        }
      '';
      description = ''
        Extra HyperHDR settings, keyed by settings type (`smoothing`,
        `color`, `device`, ...; see HyperHDR's `sources/base/schema/`),
        merged over the generated ones.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.channels != [ ];
        message = "my.hue-sync.channels needs at least one screen region.";
      }
      {
        assertion = cfg.entertainmentArea != "";
        message = "my.hue-sync.entertainmentArea must be set (hue-sync-setup areas).";
      }
    ];

    home.packages = [
      setup
      applyConfig
    ];

    systemd.user.services.hue-sync = {
      Unit = {
        Description = "Philips Hue screen sync (HyperHDR)";
        # The screen comes through the portal, so wait for the session
        After = [
          "graphical-session.target"
          "xdg-desktop-portal.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStartPre = getExe applyConfig;
        # --service: console daemon, no systray. --pipewire: HyperHDR only
        # tries the portal grabber for a GUI app unless forced.
        ExecStart = "${getExe' cfg.package "hyperhdr"} --service --pipewire --userdata ${cfg.dataDir}";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
