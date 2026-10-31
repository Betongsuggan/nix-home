# The launcher: a thin wrapper over the standalone launcher flake
# (github:Betongsuggan/launcher, `programs.launcher`), keeping the
# `my.launcher` API other modules build on: `dmenu`, `show` and the menus.
# The flake writes no keybinds here; my.window-manager.keybinds binds the
# menus like everything else.
{
  config,
  lib,
  pkgs,
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

  # vicinae's emoji picker only copies (no paste action, no setting for one),
  # so the symbols menu waits for the pick to land in the clipboard and types
  # it into the focused window. Only a new, short, single-line value counts,
  # so cancelling and copying something else later never pastes it
  pasteSymbols = pkgs.writeShellApplication {
    name = "launcher-symbols-paste";
    runtimeInputs = [
      pkgs.wl-clipboard
      pkgs.wtype
    ];
    text = ''
      before=$(wl-paste --no-newline 2>/dev/null || true)
      ${launcher.menus.symbols}
      now=$before
      for _ in $(seq 300); do
        sleep 0.1
        now=$(wl-paste --no-newline 2>/dev/null || true)
        [ "$now" = "$before" ] || break
      done
      case $now in
        *$'\n'*) exit 0 ;;
      esac
      if [ "$now" = "$before" ] || [ "''${#now}" -gt 16 ]; then
        exit 0
      fi
      # Let the launcher close so the target window has focus again
      sleep 0.2
      wtype -- "$now"
    '';
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
        let
          menu = showModes.${mode} or "applications";
        in
        if menu == "symbols" && launcher.backend == "vicinae" then
          getExe pasteSymbols
        else
          launcher.menus.${menu};
      wifi = menu "wifi";
      bluetooth = menu "bluetooth";
      audioOutput = menu "audioOutput";
      audioInput = menu "audioInput";
      monitor = menu "monitor";
    };
  };
}
