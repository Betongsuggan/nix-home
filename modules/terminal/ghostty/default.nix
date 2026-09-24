{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.terminal;

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

in
{
  config = mkIf config.my.terminal.ghostty.enable {
    # Colors, font and opacity are applied by stylix from config.my.theming.*
    stylix.targets.ghostty.enable = cfg.colors.useTheme;
    stylix.fonts.sizes.terminal = cfg.font.size;
    stylix.opacity.terminal = cfg.opacity;

    programs.ghostty = {
      enable = true;
      settings = {
        # Wayland settings
        window-decoration = false;
        gtk-single-instance = true;

        # Disable shell integration to avoid conflicts with existing prompts
        shell-integration = "none";
        scrollback-limit = 10000;
        clipboard-read = "allow";
        clipboard-write = "allow";

        # Ghostty doesn't use fontconfig fallback: route emoji to a color font
        font-codepoint-map = map (range: "${range}=Noto Color Emoji") emojiRanges;
        keybind = cfg.ghostty.keybindings;
      }
      # An explicit family wins over stylix's
      // optionalAttrs (cfg.font.family != null) { font-family = mkForce cfg.font.family; }
      // cfg.ghostty.extraSettings;
    };
  };
}
