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

  configDir = "/root/.config/input-remapper-2";

  # One `L+` (replace) symlink per device preset
  presetRules = mapAttrsToList (
    deviceName: device:
    let
      sanitized = sanitizeDeviceName deviceName;
      presetFile = pkgs.writeText "${sanitized}-${device.preset}.json" (
        builtins.toJSON (map mkMappingEntry device.mappings)
      );
    in
    "L+ \"${configDir}/presets/${sanitized}/${device.preset}.json\" - - - - ${presetFile}"
  ) cfg.devices;

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
    };

    # The root daemon reads its config and presets from /root; link the
    # generated files there (parent directories are created as needed).
    # Presets made in the GUI next to them are left alone.
    systemd.tmpfiles.rules = [
      "L+ ${configDir}/config.json - - - - ${configFile}"
    ]
    ++ presetRules;

    # Autoload presets for already-connected devices after service restart
    systemd.services.input-remapper.postStart = ''
      sleep 1
      ${pkgs.input-remapper}/bin/input-remapper-control --command autoload || true
    '';
  };
}
