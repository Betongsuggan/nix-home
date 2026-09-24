{ pkgs, inputs, ... }:
{
  home.stateVersion = "25.05";

  my.general.enable = true;
  my.games.enable = true;
  my.communication.enable = true;
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

  my.terminal = {
    enable = true;
    backend = "alacritty";
  };

  my.starship.enable = true;
  my.shell = {
    enable = true;
    backend = "bash";
  };

  my.notifications.enable = true;
  my.network-monitor.enable = true;
  my.battery-monitor.enable = false;
  my.file-manager = {
    enable = true;
    backend = "thunar";
  };
  my.chromium.enable = true;
  my.launcher = {
    enable = true;
    backend = "vicinae";
    vicinae = {
      extensions = with pkgs; [
        vicinae-wifi-commander
        vicinae-bluetooth
        vicinae-monitor
      ];
    };
  };

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
    enable = true;
    backend = "hyprland";
    monitors = [
      "DP-2,3440x1440@240,auto,1,bitdepth,10,cm,hdr,sdrbrightness,1.0,sdrsaturation,1.5"
      "HDMI-A-1,disable"
      ",preferred,auto,1"
    ];
    autostartApps = {
      chromium = {
        command = "chromium";
        workspace = 1;
      };
    };
  };
  my.theming = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
  };
  my.git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "rydback@gmail.com";
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

  services.ssh-agent = {
    enable = true;
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  programs.ssh = {
    enable = true;
    # The legacy implicit defaults ("*" block) match OpenSSH's own defaults;
    # nothing needs preserving.
    enableDefaultConfig = false;
    settings = {
      "controller ${inputs.self.lib.tailnet.fqdn "controller"}" = {
        HostName = inputs.self.lib.tailnet.fqdn "controller";
        User = "betongsuggan";
        IdentityFile = "/home/betongsuggan/.ssh/id_rsa";
        IdentitiesOnly = true;
      };
    };
  };

}
