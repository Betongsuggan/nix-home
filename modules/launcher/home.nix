{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.launcher;

  args = additionalArgs: concatStringsSep " " additionalArgs;

  # What each backend provides. A missing entry means the backend has no such
  # menu, and the corresponding API function below is null.
  backends = {
    wofi = {
      dmenu = cfg.wofi.buildDmenuCmd;
      show = cfg.wofi.buildShowCmd;
      wifi = _: "${cfg.wofi.wifi}/bin/wifi-control";
      bluetooth = _: "${cfg.wofi.bluetooth}/bin/bluetooth-control";
    };
    rofi = {
      dmenu = cfg.rofi.buildDmenuCmd;
      show = cfg.rofi.buildShowCmd;
      wifi = _: "${cfg.rofi.wifi}/bin/wifi-control";
      bluetooth = _: "${cfg.rofi.bluetooth}/bin/bluetooth-control";
    };
    walker = {
      dmenu = cfg.walker.buildDmenuCmd;
      show = cfg.walker.buildShowCmd;
      wifi =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.unstable.iwmenu}/bin/iwmenu --launcher walker --spaces 2 ${args additionalArgs}";
      bluetooth =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.unstable.bzmenu}/bin/bzmenu --launcher walker --spaces 2 ${args additionalArgs}";
      audioOutput =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.audiomenu}/bin/audiomenu sink --launcher walker ${args additionalArgs}";
      audioInput =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.audiomenu}/bin/audiomenu source --launcher walker ${args additionalArgs}";
      monitor =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.monitormenu}/bin/monitormenu --launcher walker ${args additionalArgs}";
    };
    vicinae = {
      dmenu = cfg.vicinae.buildDmenuCmd;
      show = cfg.vicinae.buildShowCmd;
      wifi =
        {
          additionalArgs ? [ ],
        }:
        "${lib.getExe config.programs.vicinae.package} deeplink vicinae://launch/@dagimg-dot/wifi-commander/scan-wifi ${args additionalArgs}";
      bluetooth =
        {
          additionalArgs ? [ ],
        }:
        "${lib.getExe config.programs.vicinae.package} deeplink vicinae://launch/@Gelei/bluetooth/devices ${args additionalArgs}";
      audioOutput =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.audiomenu}/bin/audiomenu sink --launcher vicinae ${args additionalArgs}";
      audioInput =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.audiomenu}/bin/audiomenu source --launcher vicinae ${args additionalArgs}";
      monitor =
        {
          additionalArgs ? [ ],
        }:
        "${pkgs.monitormenu}/bin/monitormenu --launcher vicinae --backend ${cfg.windowManager} ${args additionalArgs}";
    };
  };

  features = [
    "dmenu"
    "show"
    "wifi"
    "bluetooth"
    "audioOutput"
    "audioInput"
    "monitor"
  ];

in
{
  imports = [
    ./wofi
    ./rofi
    ./walker
    ./vicinae
  ];

  options.my.launcher = {
    enable = mkEnableOption "launcher system";

    backend = mkOption {
      type = types.enum [
        "wofi"
        "rofi"
        "walker"
        "vicinae"
      ];
      default = "vicinae";
      description = "Which launcher to use";
    };

    windowManager = mkOption {
      type = types.enum [
        "hyprland"
        "niri"
        "sway"
        "i3"
        "generic"
      ];
      default = if config.my.window-manager.enable then config.my.window-manager.backend else "generic";
      defaultText = literalExpression "my.window-manager.backend, or \"generic\" without one";
      description = "Window manager for session integration.";
    };

    dmenu = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate dmenu-style launcher commands.

        Usage:
          config.my.launcher.dmenu {
            prompt = "Select an option";
            password = false;
            insensitive = true;
            multiSelect = false;
            allowImages = true;
            additionalArgs = [ "--width" "500" ];
          }

        Returns a shell command string.
      '';
    };

    show = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate application launcher commands.

        Usage:
          config.my.launcher.show {
            mode = "drun";  # or "run", "applications", etc.
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    wifi = mkOption {
      type = types.nullOr (types.functionTo types.str);
      internal = true;
      readOnly = true;
      description = ''
        Function to generate WiFi network selection launcher.

        Usage:
          config.my.launcher.wifi {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    bluetooth = mkOption {
      type = types.nullOr (types.functionTo types.str);
      internal = true;
      readOnly = true;
      description = ''
        Function to generate Bluetooth device selection launcher.

        Usage:
          config.my.launcher.bluetooth {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    audioOutput = mkOption {
      type = types.nullOr (types.functionTo types.str);
      internal = true;
      readOnly = true;
      description = ''
        Function to generate audio output device selection launcher.

        Usage:
          config.my.launcher.audioOutput {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    audioInput = mkOption {
      type = types.nullOr (types.functionTo types.str);
      internal = true;
      readOnly = true;
      description = ''
        Function to generate audio input device selection launcher.

        Usage:
          config.my.launcher.audioInput {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };

    monitor = mkOption {
      type = types.nullOr (types.functionTo types.str);
      internal = true;
      readOnly = true;
      description = ''
        Function to generate monitor configuration launcher.

        Usage:
          config.my.launcher.monitor {
            additionalArgs = [];
          }

        Returns a shell command string.
      '';
    };
  };

  # The API: each function comes from the selected backend, or is null when
  # the backend has no such menu (callers skip their binding then)
  config = mkIf cfg.enable {
    my.launcher = genAttrs features (f: backends.${cfg.backend}.${f} or null);
  };
}
