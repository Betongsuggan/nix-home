{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.stateVersion = "24.05";

  my.development = {
    enable = true;
    python.enable = true;
    node.enable = true;
    go.enable = true;
    kotlin.enable = true;
  };
  my.direnv.enable = true;
  my.firefox.enable = true;
  my.media.enable = true;
  my.localsend = {
    enable = true;
    cli = true;
  };
  my.printing-3d = {
    enable = true;
    cad.enable = true;
  };
  my.file-manager = {
    networkShares.enable = true;
    # Shares on the tailnet can't be discovered via mDNS (multicast doesn't
    # route over Tailscale), so bookmark them directly instead
    bookmarks = [
      "smb://${inputs.self.lib.tailnet.fqdn "controller"}/emulation-roms ROMs (controller)"
    ];
  };

  my.notifications.enable = true;
  my.network-monitor.enable = true;

  my.controls = {
    enable = true;
    brightness.backend = "brightnessctl";
  };

  my.window-manager = {
    composeKey = "ralt";
    # No autostart: Chromium and Slack are both Electron apps that cost ~1-1.5 W
    # idle and were the top CPU consumers at every login. Launch them from the
    # Vicinae launcher when they're actually wanted.
  };

  my.sops.enable = true;

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

  my.emulation-client = {
    enable = true;
    server.address = inputs.self.lib.tailnet.fqdn "controller";
  };

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
