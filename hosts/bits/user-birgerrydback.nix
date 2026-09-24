{
  pkgs,
  inputs,
  ...
}:

{
  home.stateVersion = "24.05";

  home.file.".ssh/bits.pub".text = inputs.self.lib.hosts.bits.users.birgerrydback.ssh.bits + "\n";
  home.file.".ssh/id_rsa.pub".text = inputs.self.lib.hosts.bits.users.birgerrydback.ssh.id_rsa + "\n";

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

  my.git = {
    enable = true;
    userName = "BirgerRydback";
    userEmail = "birger.rydback@bits.bi";
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

  services.ssh-agent = {
    enable = true;
  };

  my.emulation-client = {
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
