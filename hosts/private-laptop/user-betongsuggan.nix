{ pkgs, inputs, ... }:
{
  home.stateVersion = "24.05";

  # Kept light, like bits: Hyprland (the window-manager default), Alacritty
  # (the terminal default), Firefox instead of Chromium, no Slack. Toolchains
  # come from each repo's dev shell (`use flake` in .envrc, cached by
  # nix-direnv); globally only gh and the AI tools, and the editor keeps only
  # Nix (its other languages follow the toolchain flags, all off)
  my.development = {
    enable = true;
    infra.enable = false;
  };
  my.direnv.enable = true;
  my.firefox.enable = true;
  my.chromium.enable = false;
  my.communication.enable = false;

  my.game-streaming.client.enable = true;
  # Steam and Moonlight only; no store launchers/Wine prefix managers here
  my.games = {
    enable = true;
    tools.enable = false;
    # Overlay only for games launched with `mangohud`
    mangohud.sessionWide = false;
  };
  my.notifications.enable = true;
  my.network-monitor.enable = true;

  # Convertible: follow the accelerometer
  my.controls.utils.autoScreenRotation = true;

  # The LG TV (through a USB-C to HDMI adapter) at its preferred 4K@60.
  # Hyprland's default `highres` picks 4K@120, which Tiger Lake's DP 1.4 link
  # only fits in a converted colour format, and the colours come out wrong
  # (yellow turns green). Matched by description: any USB-C port
  my.window-manager.monitors."desc:LG Electronics LG TV SSCR2 0x01010101".mode = {
    width = 3840;
    height = 2160;
    refresh = 60;
  };

  my.sops.enable = true;

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
