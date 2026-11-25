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
