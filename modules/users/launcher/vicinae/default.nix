{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

  buildDmenuCmd = { prompt ? null, password ? false, insensitive ? false
    , multiSelect ? false, allowImages ? null, additionalArgs ? [ ] }:
    let
      promptArg = optionalString (prompt != null) "-p '${prompt}'";
      # Note: vicinae dmenu doesn't support password mode or case-insensitive search via CLI args
      # These are handled through the UI
      additionalArgsStr = concatStringsSep " " additionalArgs;
    in "${pkgs.vicinae}/bin/vicinae dmenu ${promptArg} ${additionalArgsStr}";

  buildShowCmd = { mode ? "applications", additionalArgs ? [ ] }:
    # Vicinae uses deeplinks for showing specific interfaces
    # The daemon must be running for this to work
    let
      additionalArgsStr = concatStringsSep " " additionalArgs;
      # Map mode names to vicinae deeplinks
      deeplink = if mode == "clipboard" then
        "vicinae://extensions/vicinae/clipboard/history"
      else if mode == "symbols" || mode == "emoji" then
        "vicinae://extensions/vicinae/vicinae/search-emojis"
      else if mode == "websearch" then
        # Vicinae doesn't have a built-in websearch, just open normally
        "vicinae://open"
      else if mode == "desktopapplications" || mode == "applications" || mode == "drun" then
        # Just open the main launcher for applications
        "vicinae://open"
      else
        # For any other mode, just open vicinae
        "vicinae://open";
    in "${pkgs.vicinae}/bin/vicinae deeplink ${deeplink} ${additionalArgsStr}";

in {
  options.launcher.vicinae = {
    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Vicinae settings (JSON configuration)";
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        List of Vicinae extensions to install.
        Use mkVicinaeExtension from vicinae flake to create extensions.
      '';
    };

    themes = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Custom themes to add to vicinae.
        Attribute name becomes the theme name.
      '';
      example = literalExpression ''
        {
          my-custom-theme = {
            version = "1.0.0";
            appearance = "dark";
            name = "My Custom Theme";
            palette = {
              background = "#1e1e1e";
              foreground = "#d4d4d4";
            };
          };
        }
      '';
    };

    useLayerShell = mkOption {
      type = types.bool;
      default = true;
      description = "Whether vicinae should use layer shell";
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
    launcher.vicinae.buildDmenuCmd = buildDmenuCmd;
    launcher.vicinae.buildShowCmd = buildShowCmd;

    # Use vicinae's official home-manager module
    services.vicinae = {
      enable = true;
      package = pkgs.vicinae;
      autoStart = true;
      useLayerShell = cfg.vicinae.useLayerShell;

      # Merge user-provided configuration
      settings = cfg.vicinae.config;
      extensions = cfg.vicinae.extensions;
      themes = cfg.vicinae.themes;
    };

    # Vicinae uses external tools (iwmenu, bzmenu) so we ensure they're available
    home.packages = with pkgs; [ unstable.bzmenu unstable.iwmenu ];
  };
}
