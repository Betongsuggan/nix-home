{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.stateVersion = "24.05";

  # Toolchains and cloud tools come from each repo's dev shell (`use flake`
  # in .envrc, cached by nix-direnv); globally only gh and the AI tools.
  # The editor keeps its Go and TypeScript language servers, which would
  # otherwise follow the (now off) toolchain flags
  my.development = {
    enable = true;
    infra.enable = false;
  };
  my.editor.languages = {
    go = true;
    typescript = true;
  };
  my.direnv.enable = true;
  # Firefox handles DRM streaming here; skip the second (Widevine) Chromium build
  my.chromium.widevine = false;
  my.firefox.enable = true;
  my.media.enable = true;
  # Steam-focused: Proton-GE in Steam's compat list, MangoHud only for games
  # launched with `mangohud`, no store launchers/Wine prefix managers, no
  # emulators. Discord comes with the module. Steam itself renders on the
  # discrete GPU (my.games.steam.env in system.nix); raise the platform
  # profile per game with `gamemoderun %command%` (my.power-management
  # .platformProfiles.gaming in system.nix).
  my.games = {
    enable = true;
    protonGE.enable = true;
    tools.enable = false;
    mangohud.sessionWide = false;
    # Battle.net in ~/Games/battlenet, installed on first launch; its games
    # render on the discrete GPU like Steam's (my.games.steam.env)
    wineApps.battlenet = {
      enable = true;
      env.DRI_PRIME = "pci-0000_03_00_0";
    };
  };
  # Moonlight client for the desktop's Sunshine session (pair once via the
  # Sunshine web UI, see modules/game-streaming/SPEC.md)
  my.game-streaming.client = {
    enable = true;
    # The panel is 1920x1200@60: a 120 fps request makes Moonlight disable
    # frame pacing ("target 60 Hz with 120 FPS stream")
    resolution = {
      width = 1920;
      height = 1200;
    };
    fps = 60;
  };
  my.printing-3d = {
    enable = true;
    cad.enable = true;
  };
  my.file-manager.networkShares.enable = true;
  # Top-level folders of ~ that belong there (see modules/home-check)
  my.home-check.allowed = [
    "Games"
    "emulation"
    "roms"
  ];

  my.notifications.enable = true;
  my.network-monitor.enable = true;

  my.controls = {
    enable = true;
    brightness.backend = "brightnessctl";
  };

  my.theming.scheme = "kanagawa";
  my.window-manager = {
    composeKey = "ralt";
    # No autostart: Chromium and Slack are both Electron apps that cost ~1-1.5 W
    # idle and were the top CPU consumers at every login. Launch them from the
    # Vicinae launcher when they're actually wanted.
  };

  my.sops.enable = true;

  # Project tracker: `deck` talks to Nextcloud Deck on controller as the
  # `birger` Nextcloud account (app password from the vault). See modules/deck/SPEC.md
  my.deck = {
    enable = true;
    user = "birger";
  };

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

  # Work project shortcuts
  my.shell.aliases = {
    cloud = "cd ~/Development/cloud";
    dashboard = "cd ~/Development/web/apps/dashboard";
    nocode = "cd ~/Development/web/apps/nocode";
    demo = "cd ~/Development/web/apps/nocode-demo";
  };

  # GitHub identities; fleet Host blocks come from the ssh module
  programs.ssh.settings = {
    "github.com-betongsuggan" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "${config.home.homeDirectory}/.ssh/id_rsa";
    };
    "github.com" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "${config.home.homeDirectory}/.ssh/bits";
    };
  };

}
