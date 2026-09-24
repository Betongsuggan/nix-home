{ pkgs, inputs, ... }:

{
  home.stateVersion = "25.05";

  my.games.enable = true;
  my.localsend.enable = true;
  my.development = {
    enable = true;
    python.enable = true;
    node.enable = true;
    go.enable = true;
  };

  my.notifications.enable = true;
  my.network-monitor.enable = true;

  # Enable PS5 controller support with MangoHud toggle
  my.controller = {
    enable = true;
    type = "ps5";
    mangohudToggle = {
      enable = true;
      buttons = [
        "square"
        "triangle"
      ]; # Press Square or Triangle to toggle
      autoStart = true;
    };
  };
  my.sops.enable = true;

  my.window-manager = {
    autostartApps = {
      chromium = {
        command = "chromium";
        workspace = 1;
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
    ];
  };

}
