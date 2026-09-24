{ pkgs, inputs, ... }:

{
  home.stateVersion = "25.11";

  home.file.".ssh/id_ed25519.pub".text =
    inputs.self.lib.hosts.controller.users.betongsuggan.ssh.ssh_ed25519 + "\n";

  my.general.enable = true;
  my.starship.enable = true;

  home.packages = with pkgs; [
    unstable.claude-code
  ];

  my.terminal = {
    enable = true;
    backend = "alacritty";
  };

  my.shell = {
    enable = true;
    backend = "bash";
  };

  my.sops.enable = true;
  #chromium.enable = true;
  #notifications.enable = true;

  #launcher = {
  #  enable = true;
  #  backend = "vicinae";
  #  vicinae = {
  #    extensions = with pkgs; [
  #      vicinae-wifi-commander
  #      vicinae-bluetooth
  #      vicinae-monitor
  #    ];
  #  };
  #};

  #windowManager = {
  #  enable = true;
  #  backend = "niri";
  #  composeKey = "ralt";
  #  monitors = [ ",preferred,auto,1" ];
  #};

  my.theming = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    #cursor = {
    #  package = pkgs.banana-cursor;
    #  name = "Banana";
    #};
  };

  my.git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "birger.rydback@gmail.com";
  };

  services.ssh-agent = {
    enable = true;
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

}
