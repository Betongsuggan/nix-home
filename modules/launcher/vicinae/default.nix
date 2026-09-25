{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.my.launcher;
  vcfg = cfg.vicinae;
  vicinae = lib.getExe config.programs.vicinae.package;

  # An extension from the vicinae-extensions input, installed under its own
  # name. Its provider id in `vicinae://launch/<id>/<command>` is
  # `@<author>/<name>` from its package.json (`vicinae cmd ls` lists them).
  # Extensions whose tsconfig extends the repository root's lose it when
  # built on their own, and the bundler then falls back to classic JSX (a
  # bare `React` global vicinae doesn't provide); point it at the root's.
  extension =
    name:
    (config.lib.vicinae.mkExtension {
      inherit name;
      src = "${inputs.vicinae-extensions}/extensions/${name}";
    }).overrideAttrs
      {
        postPatch = ''
          substituteInPlace tsconfig.json --replace-quiet \
            '"../../tsconfig.json"' '"${inputs.vicinae-extensions}/tsconfig.json"'
        '';
      };

  # vicinae's dmenu has no CLI flags for password, case-insensitive,
  # multi-select or image modes; those arguments are accepted and ignored
  buildDmenuCmd =
    {
      prompt ? null,
      additionalArgs ? [ ],
      ...
    }:
    concatStringsSep " " (
      [ "${vicinae} dmenu" ] ++ optional (prompt != null) "-p '${prompt}'" ++ additionalArgs
    );

  # The daemon must be running; menus are opened through deeplinks
  deeplinks = {
    clipboard = "vicinae://launch/clipboard/history";
    symbols = "vicinae://launch/core/search-emojis";
    emoji = "vicinae://launch/core/search-emojis";
  };
  buildShowCmd =
    {
      mode ? "applications",
      additionalArgs ? [ ],
    }:
    concatStringsSep " " (
      [ "${vicinae} deeplink ${deeplinks.${mode} or "vicinae://toggle"}" ] ++ additionalArgs
    );

in
{
  options.my.launcher.vicinae = {
    config = mkOption {
      type = (pkgs.formats.json { }).type;
      default = { };
      description = "Extra vicinae settings, merged into `programs.vicinae.settings` (settings.json)";
    };

    extensions = mkOption {
      type = types.listOf types.package;
      # The monitor extension drives hyprctl, so it only makes sense there
      default = [
        (extension "wifi-commander")
        (extension "bluetooth")
      ]
      ++ optional (config.my.window-manager.enable && config.my.window-manager.backend == "hyprland") (
        extension "hyprland-monitors"
      );
      defaultText = literalExpression "wifi-commander and bluetooth, plus hyprland-monitors under Hyprland";
      description = "Vicinae extensions to install (build more with `config.lib.vicinae.mkExtension`)";
    };

    themes = mkOption {
      type = (pkgs.formats.toml { }).type;
      default = { };
      description = "Extra vicinae themes (TOML), keyed by theme file name";
    };

    useLayerShell = mkOption {
      type = types.bool;
      default = true;
      description = "Whether vicinae should use layer shell";
    };

    fileIndex = {
      enable = mkEnableOption ''
        vicinae's background file indexer (file search). It walks every
        configured path, including hidden directories, and re-sweeps them
        periodically, so it is off unless enabled
      '';
      paths = mkOption {
        type = types.listOf types.str;
        default = [ config.home.homeDirectory ];
        defaultText = literalExpression "[ config.home.homeDirectory ]";
        description = "Directories to index";
      };
      exclude = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Directories to leave out of the index";
      };
    };

    buildDmenuCmd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = "Function to build vicinae dmenu commands";
    };

    buildShowCmd = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = "Function to build vicinae show commands";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "vicinae") {
    my.launcher.vicinae.buildDmenuCmd = buildDmenuCmd;
    my.launcher.vicinae.buildShowCmd = buildShowCmd;

    # Theme vicinae from the base16 scheme (adds a "stylix" theme and
    # selects it in programs.vicinae.settings)
    stylix.targets.vicinae.enable = true;

    programs.vicinae = {
      enable = true;
      # Started with the graphical session, whichever window manager runs it
      systemd.enable = true;
      inherit (vcfg) extensions themes;

      # settings.json is a read-only store link, so changes made in the
      # settings window don't persist; configure vicinae here instead
      settings = lib.mkMerge [
        {
          launcher_window.layer_shell.enabled = vcfg.useLayerShell;
          providers.files.preferences = {
            autoIndexing = vcfg.fileIndex.enable;
            indexingPaths = vcfg.fileIndex.paths;
            excludedIndexingPaths = vcfg.fileIndex.exclude;
          };
          # A required preference, otherwise asked for on first launch; the
          # tool follows the host's network stack
          providers."@dagimg-dot/wifi-commander".preferences.network-cli-tool =
            if osConfig.networking.networkmanager.enable then "nmcli" else "iwctl";
        }
        vcfg.config
      ];
    };
  };
}
