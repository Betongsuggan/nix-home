{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.terminal;

  # Use terminal font family or fall back to theme font
  fontFamily = if cfg.font.family != null then cfg.font.family else config.my.theming.font.name;

  # Unicode emoji ranges - route these to color emoji font
  # This is needed because Ghostty doesn't use fontconfig fallback
  emojiRanges = [
    "U+1F300-U+1F5FF" # Misc Symbols and Pictographs
    "U+1F600-U+1F64F" # Emoticons
    "U+1F680-U+1F6FF" # Transport and Map
    "U+1F900-U+1F9FF" # Supplemental Symbols and Pictographs
    "U+1FA00-U+1FAFF" # Symbols and Pictographs Extended-A
    "U+2600-U+26FF" # Misc Symbols
    "U+2700-U+27BF" # Dingbats
  ];

  # Build color palette for Ghostty (indices 0-15)
  colorPalette = optionals cfg.colors.useTheme [
    "0=${config.my.theming.colors.normal.black}"
    "1=${config.my.theming.colors.normal.red}"
    "2=${config.my.theming.colors.normal.green}"
    "3=${config.my.theming.colors.normal.yellow}"
    "4=${config.my.theming.colors.normal.blue}"
    "5=${config.my.theming.colors.normal.magenta}"
    "6=${config.my.theming.colors.normal.cyan}"
    "7=${config.my.theming.colors.normal.white}"
    "8=${config.my.theming.colors.bright.black}"
    "9=${config.my.theming.colors.bright.red}"
    "10=${config.my.theming.colors.bright.green}"
    "11=${config.my.theming.colors.bright.yellow}"
    "12=${config.my.theming.colors.bright.blue}"
    "13=${config.my.theming.colors.bright.magenta}"
    "14=${config.my.theming.colors.bright.cyan}"
    "15=${config.my.theming.colors.bright.white}"
  ];

  # Base settings for Ghostty
  baseSettings = {
    font-family = fontFamily;
    font-size = cfg.font.size;

    # Wayland/Hyprland settings
    window-decoration = false;
    gtk-single-instance = true;

    # Disable shell integration to avoid conflicts with existing prompts
    shell-integration = "none";
    scrollback-limit = 10000;
    clipboard-read = "allow";
    clipboard-write = "allow";
  }
  // optionalAttrs (cfg.opacity < 1.0) {
    background-opacity = cfg.opacity;
  }
  // optionalAttrs cfg.colors.useTheme {
    background = config.my.theming.colors.primary.background;
    foreground = config.my.theming.colors.primary.foreground;
    selection-background = config.my.theming.colors.normal.white;
    selection-foreground = config.my.theming.colors.bright.black;
  };

  # Merge base settings with extra settings
  finalSettings = baseSettings // cfg.ghostty.extraSettings;

  # Convert settings to Ghostty config format
  formatValue =
    v:
    if isBool v then
      (if v then "true" else "false")
    else if isInt v then
      toString v
    else if isFloat v then
      toString v
    else
      toString v;

  settingsLines = mapAttrsToList (name: value: "${name} = ${formatValue value}") finalSettings;
  paletteLines = map (p: "palette = ${p}") colorPalette;

  # Generate font-codepoint-map lines for emoji
  emojiFont = "Noto Color Emoji";
  emojiMapLines = map (range: "font-codepoint-map = ${range}=${emojiFont}") emojiRanges;

  # Generate keybind lines
  keybindLines = map (kb: "keybind = ${kb}") cfg.ghostty.keybindings;

  configText = concatStringsSep "\n" (settingsLines ++ paletteLines ++ emojiMapLines ++ keybindLines);

in
{
  config = mkIf config.my.terminal.ghostty.enable {
    home.packages = [ pkgs.ghostty ];

    xdg.configFile."ghostty/config".text = configText;
  };
}
