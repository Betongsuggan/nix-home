# The launcher: a thin wrapper over the standalone launcher flake
# (github:Betongsuggan/launcher, `programs.launcher`), keeping the
# `my.launcher` API other modules build on: `dmenu`, `show` and the menus.
# The flake writes no keybinds here; my.window-manager.keybinds binds the
# menus like everything else.
{
  config,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.launcher;
  launcher = config.programs.launcher;
  wm = config.my.window-manager;

  # `show { mode }` names from the old backends -> the flake's menus
  showModes = {
    applications = "applications";
    desktopapplications = "applications";
    drun = "applications";
    websearch = "webSearch";
    symbols = "symbols";
    emoji = "symbols";
    clipboard = "clipboard";
  };

  # A menu as a function (callers pass `{ }`), or null when the flake has none
  menu = action: if launcher.menus.${action} == null then null else (_: launcher.menus.${action});

  menuOption =
    what:
    mkOption {
      type = types.nullOr (types.functionTo types.str);
      internal = true;
      readOnly = true;
      description = ''
        Function to generate the ${what} launcher; null when the backend has no such menu.

        Usage: config.my.launcher.${what} { }

        Returns a shell command string.
      '';
    };
in
{
  imports = [ inputs.launcher.homeModules.default ];

  options.my.launcher = {
    enable = mkEnableOption "launcher system";

    dmenu = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate dmenu-style launcher commands.

        Usage:
          config.my.launcher.dmenu {
            prompt = "Select an option";
            additionalArgs = [ ];
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
            mode = "drun";  # applications, websearch, symbols, clipboard
          }

        Returns a shell command string.
      '';
    };

    wifi = menuOption "wifi";
    bluetooth = menuOption "bluetooth";
    audioOutput = menuOption "audioOutput";
    audioInput = menuOption "audioInput";
    monitor = menuOption "monitor";
  };

  config = mkIf cfg.enable {
    programs.launcher = {
      enable = true;
      # The compositor, for the monitor menu; binds come from my.window-manager
      windowManager =
        if
          wm.enable
          && elem wm.backend [
            "hyprland"
            "niri"
            "sway"
          ]
        then
          wm.backend
        else
          null;
      keybinds.enable = false;
      terminal = "${config.my.terminal.command} -e";
    };

    # Theme vicinae from the base16 scheme (stylix.autoEnable is off
    # fleet-wide, modules/theming)
    stylix.targets.vicinae.enable = true;

    my.launcher = {
      inherit (launcher) dmenu;
      show =
        {
          mode ? "applications",
          ...
        }:
        launcher.menus.${showModes.${mode} or "applications"};
      wifi = menu "wifi";
      bluetooth = menu "bluetooth";
      audioOutput = menu "audioOutput";
      audioInput = menu "audioInput";
      monitor = menu "monitor";
    };
  };
}
