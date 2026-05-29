{
  pkgs,
  inputs,
  lib,
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
    inputs.nix-vault.keys.hosts.bits.users.birgerrydback.bits + "\n";
  home.file.".ssh/id_rsa.pub".text =
    inputs.nix-vault.keys.hosts.bits.users.birgerrydback.id_rsa + "\n";

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
  communication.enable = true;
  localsend = {
    enable = true;
    cli = true;
  };
  battery-monitor.enable = true;
  fileManager = {
    enable = true;
    backend = "thunar";
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
    backend = "niri";
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

  secrets = {
    enable = true;
    keyProviders = [
      {
        name = "tavily_key_provider";
        path = "$HOME/.config/tavily/key_provider.sh";
        envVarName = "TAVILY_API_KEY";
      }
      {
        name = "localstack_key_provider";
        path = "$HOME/.config/localstack/key_provider.sh";
        envVarName = "LOCALSTACK_AUTH_TOKEN";
      }
    ];
  };

  programs.home-manager.enable = true;

  services.ssh-agent = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "controller controller.ts.rydback.net" = {
        hostname = builtins.head inputs.nix-vault.keys.hosts.controller.addresses;
        user = "betongsuggan";
        identityFile = "/home/birgerrydback/.ssh/bits";
        identitiesOnly = true;
      };
      "${lib.concatStringsSep " " inputs.nix-vault.keys.hosts.controller.addresses}" =
        {
          hostname = "%h";
          user = "betongsuggan";
          identityFile = "/home/birgerrydback/.ssh/bits";
          identitiesOnly = true;
        };
      "github.com-betongsuggan" = {
        hostname = "github.com";
        user = "git";
        identityFile = "/home/birgerrydback/.ssh/id_rsa";
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "/home/birgerrydback/.ssh/bits";
      };
    };
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };
}
