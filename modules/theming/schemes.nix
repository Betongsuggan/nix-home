# The color schemes `my.theming.scheme` picks from. Each has:
# - base16: the scheme file in pkgs.base16-schemes that stylix themes apps
#   with (made for base16's slot meanings, unlike a terminal palette)
# - editor: the matching Neovim colorscheme plugin (the nvim flake's
#   theme.colorscheme)
# - terminal: the scheme's own terminal palette, which modules outside
#   stylix use (my.theming.colors)
{
  gruvbox = {
    base16 = "gruvbox-dark-medium";
    editor = "gruvbox";
    terminal = {
      primary = {
        background = "#282828";
        foreground = "#ebdbb2";
      };
      normal = {
        black = "#282828";
        red = "#cc241d";
        green = "#98971a";
        yellow = "#d79921";
        blue = "#458588";
        magenta = "#b16286";
        cyan = "#689d6a";
        white = "#a89984";
      };
      bright = {
        black = "#928374";
        red = "#fb4934";
        green = "#b8bb26";
        yellow = "#fabd2f";
        blue = "#83a598";
        magenta = "#d3869b";
        cyan = "#8ec07c";
        white = "#ebdbb2";
      };
      gray = "#928374";
      orange = "#fe8019";
    };
  };

  # Kanagawa wave
  kanagawa = {
    base16 = "kanagawa";
    editor = "kanagawa";
    terminal = {
      primary = {
        background = "#1f1f28";
        foreground = "#dcd7ba";
      };
      normal = {
        black = "#16161d";
        red = "#c34043";
        green = "#76946a";
        yellow = "#c0a36e";
        blue = "#7e9cd8";
        magenta = "#957fb8";
        cyan = "#6a9589";
        white = "#c8c093";
      };
      bright = {
        black = "#727169";
        red = "#e82424";
        green = "#98bb6c";
        yellow = "#e6c384";
        blue = "#7fb4ca";
        magenta = "#938aa9";
        cyan = "#7aa89f";
        white = "#dcd7ba";
      };
      gray = "#727169";
      orange = "#ffa066";
    };
  };
}
