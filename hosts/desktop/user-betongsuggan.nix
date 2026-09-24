{ pkgs, inputs, ... }:
{
  home.stateVersion = "25.05";

  my.games.enable = true;
  my.localsend.enable = true;
  my.printing-3d.enable = true;

  my.emulation-client = {
    enable = true;
    server.address = inputs.self.lib.tailnet.fqdn "controller";
  };

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
    rumble.enable = true;
  };

  my.window-manager = {
    monitors = {
      DP-2 = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 240;
        };
        bitdepth = 10;
        hdr = true;
        sdrBrightness = 1.0;
        sdrSaturation = 1.5;
      };
      HDMI-A-1.enable = false;
    };
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

  my.sops.enable = true;

}
