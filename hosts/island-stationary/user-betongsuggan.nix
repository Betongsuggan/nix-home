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
  network-monitor.enable = true;
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
  sops-edit.enable = true;

  windowManager = {
    enable = true;
    backend = "hyprland";
    monitors = [
      ",preferred,auto,1"
    ];
    autostartApps = {
      chromium = {
        command = "chromium";
        workspace = 1;
      };
    };
  };
  services.ssh-agent = {
    enable = true;
  };

  #home.file.".ssh/id_rsa.pub".text =
  #  inputs.nix-vault.keys.hosts.island-stationary.users.betongsuggan.id_rsa + "\n";

  programs.ssh = {
    enable = true;
    # The legacy implicit defaults ("*" block) match OpenSSH's own defaults;
    # nothing needs preserving.
    enableDefaultConfig = false;
    settings = {
      # This host lives off the home LAN, so controller is only reachable over
      # the tailnet. Both identities are offered: the sops-provisioned id_rsa
      # (steady state) and the FIDO resident key (works before /run/secrets
      # exists, e.g. during onboarding).
      "controller ${inputs.self.lib.tailnet.fqdn "controller"}" = {
        HostName = inputs.self.lib.tailnet.fqdn "controller";
        User = "betongsuggan";
        IdentityFile = [
          "/home/betongsuggan/.ssh/id_rsa"
          "/home/betongsuggan/.ssh/id_ed25519_sk_rk_nix-vault"
        ];
        IdentitiesOnly = true;
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

  programs.home-manager.enable = true;
}
