{
  pkgs,
  inputs,
  ...
}:

{
  home.username = "birgerrydback";
  home.homeDirectory = "/home/birgerrydback";
  home.stateVersion = "24.05";

  imports = [
    ../../modules/user.nix
  ];

  home.file.".ssh/bits.pub".text =
    inputs.self.lib.hosts.bits.users.birgerrydback.ssh.bits + "\n";
  home.file.".ssh/id_rsa.pub".text =
    inputs.self.lib.hosts.bits.users.birgerrydback.ssh.id_rsa + "\n";

  general.enable = true;
  development = {
    enable = true;
    python.enable = true;
    node.enable = true;
    go.enable = true;
    kotlin.enable = true;
  };
  direnv.enable = true;
  chromium.enable = true;
  firefox.enable = true;
  communication.enable = true;
  localsend = {
    enable = true;
    cli = true;
  };
  battery-monitor.enable = true;
  fileManager = {
    enable = true;
    backend = "thunar";
    networkShares.enable = true;
    # Shares on the tailnet can't be discovered via mDNS (multicast doesn't
    # route over Tailscale), so bookmark them directly instead
    bookmarks = [
      "smb://${inputs.self.lib.tailnet.fqdn "controller"}/emulation-roms ROMs (controller)"
    ];
  };
  starship.enable = true;

  terminal = {
    enable = true;
    backend = "alacritty";
  };

  shell = {
    enable = true;
    backend = "bash";
  };

  notifications.enable = true;
  network-monitor.enable = true;

  controls = {
    enable = true;
    brightness.backend = "brightnessctl";
  };

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

  windowManager = {
    enable = true;
    backend = "hyprland";
    composeKey = "ralt";
    monitors = [ ",preferred,auto,1" ];
    autostartApps = {
      chromium = {
        command = "chromium";
      };

      slack = {
        command = "slack";
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
    userName = "BirgerRydback";
    userEmail = "birger.rydback@bits.bi";
  };

  sops-edit.enable = true;

  #sops-secrets = {
  #  enable = true;
  #  secretsFile = "${inputs.nix-vault}/secrets/bits.yaml";
  #};

  #secrets = {
  #  enable = true;
  #  keyProviders = [
  #    {
  #      name = "tavily_key_provider";
  #      path = "$HOME/.config/tavily/key_provider.sh";
  #      envVarName = "TAVILY_API_KEY";
  #    }
  #    {
  #      name = "localstack_key_provider";
  #      path = "$HOME/.config/localstack/key_provider.sh";
  #      envVarName = "LOCALSTACK_AUTH_TOKEN";
  #    }
  #  ];
  #};

  programs.home-manager.enable = true;

  services.ssh-agent = {
    enable = true;
  };

  emulation-client = {
    enable = true;
    server.address = inputs.self.lib.tailnet.fqdn "controller";
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
        IdentityFile = "/home/birgerrydback/.ssh/bits";
        IdentitiesOnly = true;
      };
      "desktop ${inputs.self.lib.tailnet.fqdn "desktop"}" = {
        HostName = inputs.self.lib.tailnet.fqdn "desktop";
        User = "betongsuggan";
        IdentityFile = "/home/birgerrydback/.ssh/bits";
        IdentitiesOnly = true;
      };
      "github.com-betongsuggan" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "/home/birgerrydback/.ssh/id_rsa";
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "/home/birgerrydback/.ssh/bits";
      };
    };
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };
}
