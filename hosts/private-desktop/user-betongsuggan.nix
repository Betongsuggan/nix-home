{ pkgs, inputs, ... }:
{
  home.username = "betongsuggan";
  home.homeDirectory = "/home/betongsuggan";
  home.stateVersion = "25.05";

  imports = [
    ../../modules/user.nix
  ];

  general.enable = true;
  games.enable = true;
  communication.enable = true;
  localsend.enable = true;

  emulation-client = {
    enable = true;
    server.address = inputs.self.lib.tailnet.fqdn "controller";
  };

  development = {
    enable = true;
    python.enable = true;
    node.enable = true;
    go.enable = true;
  };

  terminal = {
    enable = true;
    backend = "alacritty";
  };

  starship.enable = true;
  shell = {
    enable = true;
    backend = "bash";
  };

  notifications.enable = true;
  battery-monitor.enable = false;
  fileManager = {
    enable = true;
    backend = "thunar";
  };
  chromium.enable = true;
  launcher = {
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
  controller = {
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

  windowManager = {
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
  theme = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
  };
  git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "rydback@gmail.com";
  };
  secrets = {
    enable = true;
    keyProviders = [
      {
        name = "anthropic_key_provider";
        path = "$HOME/.config/anthropic/key_provider.sh";
        envVarName = "ANTHROPIC_API_KEY";
      }
    ];
  };

  sops-edit.enable = true;

  services.ssh-agent = {
    enable = true;
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "controller ${inputs.self.lib.tailnet.fqdn "controller"}" = {
        hostname = inputs.self.lib.tailnet.fqdn "controller";
        user = "betongsuggan";
        identityFile = "/home/betongsuggan/.ssh/id_rsa";
        identitiesOnly = true;
      };
    };
  };

  programs.home-manager.enable = true;
}
