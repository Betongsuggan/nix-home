{ pkgs, inputs, ... }:

{
  home.stateVersion = "25.05";

  my.games.enable = true;
  my.localsend.enable = true;
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
  my.sops.enable = true;

  my.window-manager = {
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

}
