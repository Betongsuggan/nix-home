{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.input-remapper;

  sanitizeDeviceName =
    name:
    replaceStrings
      [
        "/"
        "\\"
        "?"
        "%"
        "*"
        ":"
        "|"
        "\""
        "<"
        ">"
      ]
      [
        "_"
        "_"
        "_"
        "_"
        "_"
        "_"
        "_"
        "_"
        "_"
        "_"
      ]
      name;

  inputEventType = types.submodule {
    options = {
      type = mkOption {
        type = types.int;
        description = "evdev event type (1 = EV_KEY, 2 = EV_REL, 3 = EV_ABS)";
        example = 1;
      };
      code = mkOption {
        type = types.int;
        description = "evdev event code";
        example = 656;
      };
      origin_hash = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Origin hash for distinguishing devices with identical keys";
      };
      analog_threshold = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Axis threshold percentage (-100 to 100) for analog-to-digital mapping. Negative triggers below center, positive above.";
      };
    };
  };

  mappingType = types.submodule {
    options = {
      input = mkOption {
        type = types.listOf inputEventType;
        description = "Input event combination that triggers this mapping";
      };
      output = mkOption {
        type = types.str;
        description = "Output key symbol or macro string";
        example = "KEY_1";
      };
      target = mkOption {
        type = types.enum [
          "keyboard"
          "mouse"
          "gamepad"
          "keyboard + mouse"
        ];
        default = "keyboard";
        description = "Target uinput device type";
      };
    };
  };

  deviceType = types.submodule {
    options = {
      preset = mkOption {
        type = types.str;
        default = "default";
        description = "Preset name for this device";
      };
      mappings = mkOption {
        type = types.listOf mappingType;
        default = [ ];
        description = "List of key mappings for this device";
      };
    };
  };

  mkMappingEntry = mapping: {
    input_combination = map (
      input:
      {
        inherit (input) type code;
      }
      // optionalAttrs (input.origin_hash != null) { inherit (input) origin_hash; }
      // optionalAttrs (input.analog_threshold != null) { inherit (input) analog_threshold; }
    ) mapping.input;
    target_uinput = mapping.target;
    output_symbol = mapping.output;
  };

  configFile = pkgs.writeText "input-remapper-config.json" (
    builtins.toJSON {
      version = "2";
      autoload = mapAttrs (_: device: device.preset) cfg.devices;
    }
  );

  # The whole config tree (config.json + presets/<device>/<preset>.json) as one
  # store path, exposed at a stable location under /etc so the daemon can be
  # pointed at it and the unit doesn't change when mappings do.
  configDir = pkgs.linkFarm "input-remapper-config" (
    [
      {
        name = "config.json";
        path = configFile;
      }
    ]
    ++ mapAttrsToList (deviceName: device: {
      name = "presets/${sanitizeDeviceName deviceName}/${device.preset}.json";
      path = pkgs.writeText "${sanitizeDeviceName deviceName}-${device.preset}.json" (
        builtins.toJSON (map mkMappingEntry device.mappings)
      );
    }) cfg.devices
  );

  etcConfigDir = "/etc/input-remapper-2";

  busctl = "${config.systemd.package}/bin/busctl";
  dbusCall = "${busctl} call inputremapper.Control /inputremapper/Control inputremapper.Control";

in
{
  options.my.input-remapper = {
    enable = mkEnableOption "input-remapper declarative key remapping";

    devices = mkOption {
      type = types.attrsOf deviceType;
      default = { };
      description = ''
        Devices to configure, keyed by evdev device name.
        Use evtest or input-remapper-gtk to discover device names.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.input-remapper = {
      enable = true;
      enableUdevRules = true;
      # nixpkgs wants the daemon by graphical.target, which hosts that autologin
      # on a getty and start the compositor from the shell (no display manager)
      # never reach, so it never started and every udev hotplug autoload failed
      # with "Daemon missing" (exit 5). It is a root uinput injector with no
      # graphical-session dependency.
      serviceWantedBy = [ "multi-user.target" ];
    };

    environment.etc."input-remapper-2".source = configDir;

    # The root daemon loads no config on its own under systemd: it waits for a
    # *user session* to call set_config_dir over D-Bus (upstream does this from
    # an XDG autostart entry) and skips root callers such as the udev hook, so
    # files under /root/.config were never read. This is a system-wide setup,
    # so tell the daemon about the /etc tree directly at startup (Type=dbus
    # guarantees the name is owned before ExecStartPost). From then on the
    # udev rule's autoload_single covers hotplug; the autoload here covers
    # devices attached at boot.
    systemd.services.input-remapper = {
      postStart = ''
        ${dbusCall} set_config_dir s "${etcConfigDir}"
        ${dbusCall} autoload
      '';
      # Re-inject on rebuild when mappings change (the unit itself is stable)
      restartTriggers = [ configDir ];
    };
  };
}
