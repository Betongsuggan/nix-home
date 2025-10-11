{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.terminal;

  # Use terminal font family or fall back to theme font
  fontFamily = if cfg.font.family != null
    then cfg.font.family
    else config.theme.font.name;

  # Merge user-provided extra settings with defaults
  terminalSettings = recursiveUpdate {
    font = {
      size = cfg.font.size;
      normal = {
        family = fontFamily;
        style = "Medium,Regular";
      };
      bold = {
        family = fontFamily;
        style = "Bold";
      };
      italic = {
        family = fontFamily;
        style = "Italic";
      };
      bold_italic = {
        family = fontFamily;
        style = "Bold Italic";
      };
    };

    window = mkIf (cfg.opacity < 1.0) {
      opacity = cfg.opacity;
    };

    colors = mkIf cfg.colors.useTheme {
      primary = {
        inherit (config.theme.colors.primary) background foreground;
      };
      selection = {
        text = config.theme.colors.bright.black;
        background = config.theme.colors.normal.white;
      };
      normal = {
        inherit (config.theme.colors.normal)
          black red green yellow blue magenta cyan white;
      };
      bright = {
        inherit (config.theme.colors.bright)
          black red green yellow blue magenta cyan white;
      };
    };
  } cfg.alacritty.extraSettings;

in
{
  config = mkIf config.terminal.alacritty.enable {
    programs.alacritty = {
      enable = true;
      settings = terminalSettings;
    };
  };
}