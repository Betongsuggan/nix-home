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
    # ... and keeps the USB video grabber out of it. HyperHDR auto-picks any
    # V4L2 device (a webcam) and that source outranks the screen (240 < 245),
    # so without this the lights follow the camera, not the monitor.
    videoControl = {
      videoInstanceEnable = false;
      videoInstancePriority = 240;
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
            echo "Add to the vault (sops nix-vault/secrets/<host>.yaml), under services:"
            jq -r '.[0].success | "services:\n  hue:\n    app-key: \(.username)\n    client-key: \(.clientkey)"' <<< "$reply"
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

  # A no-op for users without notifications (enabling them from here would
  # recurse: the notification backends read the launcher)
  notify =
    if !config.my.notifications.enable then
      ":"
    else
      config.my.notifications.send {
        appName = "Hue Sync";
        icon = "preferences-desktop-color";
        summary = "$1";
        body = "$2";
      };

  presetsJson = pkgs.writeText "hue-sync-presets.json" (builtins.toJSON cfg.presets);

  # CLIP v2 lives on https://<bridge>/ whatever REST port `address` names
  bridgeHost = head (splitString ":" cfg.bridge.address);

  # Runtime control over HyperHDR's JSON-RPC (no token needed from localhost:
  # `network.localApiAuth` is off by default). Adjustments are live only;
  # the declared `color` row is the baseline again after a service start.
  control = pkgs.writeShellApplication {
    name = "hue-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      usage() {
        cat <<USAGE
      usage: hue-sync status | on | off | toggle | reconnect
             hue-sync preset <name>        (${concatStringsSep ", " (attrNames cfg.presets)})
             hue-sync brightness <0-100|up|down>

      on/off     resume / pause the sync (off restores the lamps' previous state)
      reconnect  restart the screen capture and re-open the entertainment
                 stream, e.g. after the Hue app took the lamps over
      preset     brightness / saturation / luminance from my.hue-sync.presets
      USAGE
      }

      notify() { ${notify}; }
      say() { echo "$1: $2"; notify "$1" "$2"; }
      api() {
        curl -fsS -m 5 -X POST "http://localhost:${toString cfg.webUi.port}/json-rpc" \
          -H 'Content-Type: application/json' -d "$1"
      }
      component() {
        api "{\"command\":\"componentstate\",\"componentstate\":{\"component\":\"$1\",\"state\":$2}}" >/dev/null
      }
      adjust() { api "{\"command\":\"adjustment\",\"adjustment\":$1}" >/dev/null; }
      serverinfo() { api '{"command":"serverinfo"}'; }
      led_enabled() { serverinfo | jq -r '.info.components[] | select(.name == "LEDDEVICE") | .enabled'; }
      last_error() { serverinfo | jq -r '.info.lastError // ""'; }
      # The bridge's own view of the area: "active <owner>", "inactive -",
      # or "unknown -" when the bridge or the app key is out of reach
      bridge_state() {
        [ -r "${cfg.bridge.appKeyFile}" ] || { echo "unknown -"; return; }
        (
          curl -fsSk -m 5 "https://${bridgeHost}/clip/v2/resource/entertainment_configuration/${cfg.entertainmentArea}" \
            -H "hue-application-key: $(tr -d '\n' < "${cfg.bridge.appKeyFile}")" \
            | jq -r '.data[0] | "\(.status) \(.active_streamer.rid // "-")"'
        ) 2>/dev/null || echo "unknown -"
      }
      # Wait up to $1 seconds for the stream to be open
      wait_streaming() {
        for _ in $(seq 1 "$(( $1 * 2 ))"); do
          [ "$(led_enabled)" = true ] && return 0
          sleep 0.5
        done
        return 1
      }
      fail() { notify "Hue sync" "$1"; echo "$1" >&2; exit 1; }

      cmd=''${1:-}
      [ -n "$cmd" ] || { usage; exit 1; }

      serverinfo >/dev/null 2>&1 || fail "HyperHDR is not reachable: is the hue-sync service running?"

      case "$cmd" in
        status)
          info=$(serverinfo)
          led=$(jq -r '.info.components[] | select(.name == "LEDDEVICE") | .enabled' <<< "$info")
          source=$(jq -r '[.info.priorities[] | select(.visible)] | first | .owner // "none"' <<< "$info")
          brightness=$(jq -r '.info.adjustment[0].brightness' <<< "$info")
          saturation=$(jq -r '.info.adjustment[0].saturationGain' <<< "$info")
          bridge=$(bridge_state)
          read -r bstatus _ <<< "$bridge"
          if [ "$led" = true ] && [ "$bstatus" != inactive ]; then
            msg="Streaming to the lamps (bridge: $bstatus). Source: $source. Brightness $brightness, saturation $saturation."
          elif [ "$led" = true ]; then
            msg="HyperHDR is streaming but the bridge says the area is inactive: run reconnect."
          else
            err=$(jq -r '.info.lastError // ""' <<< "$info")
            msg="Paused (bridge: $bstatus).''${err:+ Last error: $err}"
          fi
          say "Hue sync" "$msg"
          ;;
        on)
          component ALL true
          component LEDDEVICE true
          if wait_streaming 10; then
            say "Hue sync on" "The lamps follow the screen again."
          else
            fail "Could not start the stream: $(last_error)"
          fi
          ;;
        off)
          component ALL false
          say "Hue sync paused" "The lamps are back to normal Hue control."
          ;;
        toggle)
          if [ "$(led_enabled)" = true ]; then exec "$0" off; else exec "$0" on; fi
          ;;
        reconnect)
          # Fresh portal/PipeWire session for the grabber (it dies with "no
          # more input formats" when the session's outputs go away, e.g. a
          # VT switch or a Sunshine output change) and a fresh bridge stream
          component LEDDEVICE false
          component SYSTEMGRABBER false
          sleep 1
          component ALL true
          component SYSTEMGRABBER true
          component LEDDEVICE true
          if wait_streaming 10; then
            say "Hue sync reconnected" "Streaming to the lamps again."
          else
            fail "Reconnect failed: $(last_error)"
          fi
          ;;
        preset)
          name=''${2:-}
          values=$(jq -ce --arg n "$name" '.[$n] // empty' "${presetsJson}") \
            || fail "Unknown preset '$name' (have: $(jq -r 'keys | join(", ")' "${presetsJson}"))"
          adjust "$values"
          say "Hue sync preset: $name" "$(jq -r 'to_entries | map("\(.key) \(.value)") | join(", ")' <<< "$values")"
          ;;
        brightness)
          arg=''${2:-}
          current=$(serverinfo | jq -r '.info.adjustment[0].brightness')
          case "$arg" in
            up) value=$(( current + ${toString cfg.brightnessStep} )) ;;
            down) value=$(( current - ${toString cfg.brightnessStep} )) ;;
            "") fail "brightness needs a value, up or down" ;;
            *) value=$arg ;;
          esac
          [ "$value" -ge 0 ] 2>/dev/null || value=0
          [ "$value" -le 100 ] || value=100
          adjust "{\"brightness\":$value}"
          say "Hue sync brightness" "$value %"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    '';
  };

  presetType = types.submodule {
    options = {
      brightness = mkOption {
        type = types.ints.between 0 100;
        default = 100;
        description = "Brightness, percent.";
      };
      saturationGain = mkOption {
        type = types.numbers.between 0 10;
        default = 1.0;
        description = "Saturation gain (1.0 = as captured).";
      };
      luminanceGain = mkOption {
        type = types.numbers.between 0 10;
        default = 1.0;
        description = "Luminance gain (1.0 = as captured).";
      };
    };
  };

  # One launcher entry per action, so typing "hue" lists them all
  launcherEntries =
    let
      entry = id: name: args: {
        "hue-sync-${id}" = {
          name = "Hue Sync: ${name}";
          comment = "Philips Hue screen sync";
          exec = "${getExe control} ${args}";
          icon = "preferences-desktop-color";
          terminal = false;
          categories = [ "Utility" ];
        };
      };
      capitalize = s: toUpper (substring 0 1 s) + substring 1 (-1) s;
    in
    entry "on" "On" "on"
    // entry "off" "Off" "off"
    // entry "reconnect" "Reconnect" "reconnect"
    // entry "status" "Status" "status"
    // entry "brighter" "Brighter" "brightness up"
    // entry "dimmer" "Dimmer" "brightness down"
    // concatMapAttrs (n: _: entry "preset-${n}" (capitalize n) "preset ${n}") cfg.presets;
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

    command = mkOption {
      type = types.package;
      readOnly = true;
      default = control;
      description = "The `hue-sync` control command (for keybinds).";
    };

    presets = mkOption {
      type = types.attrsOf presetType;
      default = {
        subtle = {
          brightness = 40;
          saturationGain = 0.8;
        };
        normal = { };
        vivid = {
          saturationGain = 1.5;
          luminanceGain = 1.2;
        };
      };
      description = ''
        Runtime looks selectable with `hue-sync preset <name>` (and one
        launcher entry each). Live only: a service start returns to the
        declared `color` settings.
      '';
    };

    brightnessStep = mkOption {
      type = types.ints.between 1 100;
      default = 10;
      description = "Step for `hue-sync brightness up|down`, percent.";
    };

    launcherEntries = mkOption {
      type = types.bool;
      default = true;
      description = "Install the \"Hue Sync: ...\" desktop entries for the launcher.";
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
      control
      setup
      applyConfig
    ];

    xdg.desktopEntries = mkIf cfg.launcherEntries launcherEntries;

    # HyperHDR's PipeWire grabber only takes 8-bit formats, and Hyprland
    # hands screencopy clients the monitor's own format: on a 10-bit output
    # that is XBGR2101010, so the stream dies with "no more input formats"
    # whenever the output is in 10-bit (immediately, or at the next HDR /
    # fullscreen transition). This makes Hyprland read back 8-bit for every
    # screencopy client in the session; Sunshine's KMS capture is unaffected.
    wayland.windowManager.hyprland.settings.misc.screencopy_force_8b = mkIf (
      config.my.window-manager.enable && config.my.window-manager.backend == "hyprland"
    ) true;

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
