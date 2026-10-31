{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.stateVersion = "24.05";
  # The Home Manager options manpage is rebuilt on every evaluation
  manual.manpages.enable = false;

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
  # Gaming (Steam, Battle.net), the Moonlight client and 3D printing/CAD stay
  # off on this machine for now; each is one block to bring back (see git
  # history of this file before the Framework move)
  my.file-manager.networkShares.enable = true;

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
