{ pkgs, inputs, ... }:
{
  home.stateVersion = "24.05";

  my.game-streaming.client.enable = true;
  my.games.enable = true;
  my.notifications.enable = true;
  my.network-monitor.enable = true;
  my.kanshi.enable = true;
  my.development = {
    enable = true;
    python.enable = true;
    node.enable = true;
    go.enable = true;
  };

  my.terminal = {
    backend = "ghostty";
    colors.useTheme = true;

    ghostty.extraSettings = {
      # Disable close confirmation
      confirm-close-surface = false;

      # Quality of life
      cursor-style = "block";
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";
      unfocused-split-opacity = 0.8;
      focus-follows-mouse = true;

      # Padding
      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;
    };

    ghostty.keybindings = [
      # Scrollback to editor (vim selection workaround)
      "ctrl+shift+e=write_scrollback_file:open"

      # Vim-style scrolling
      "ctrl+shift+k=scroll_page_lines:-5"
      "ctrl+shift+j=scroll_page_lines:5"
      "ctrl+shift+u=scroll_page_up"
      "ctrl+shift+d=scroll_page_down"

      # Split navigation (vim-style)
      "ctrl+alt+h=goto_split:left"
      "ctrl+alt+j=goto_split:down"
      "ctrl+alt+k=goto_split:up"
      "ctrl+alt+l=goto_split:right"

      # Split creation
      "ctrl+alt+enter=new_split:auto"

      # Font size
      "ctrl+plus=increase_font_size:1"
      "ctrl+minus=decrease_font_size:1"
      "ctrl+0=reset_font_size"

      # Copy URL under cursor
      "ctrl+shift+y=copy_url_to_clipboard"
    ];
  };

  my.window-manager = {
    backend = "niri";
    autostartApps = {
      chromium = {
        command = "chromium";
        workspace = null;
      };

      auto-screen-rotation = {
        command = "auto-screen-rotation";
        workspace = null;
      };
    };
  };

  my.secrets = {
    enable = true;
    keyProviders = [
      {
        name = "anthropic_key_provider";
        path = "$HOME/.config/anthropic/key_provider.sh";
        envVarName = "ANTHROPIC_API_KEY";
      }
      {
        name = "tavily_key_provider";
        path = "$HOME/.config/tavily/key_provider.sh";
        envVarName = "TAVILY_API_KEY";
      }
    ];
  };

}
