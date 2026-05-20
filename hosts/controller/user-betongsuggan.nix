{ pkgs, ... }:

{
  home.username = "betongsuggan";
  home.homeDirectory = "/home/betongsuggan";
  home.stateVersion = "25.11";

  imports = [
    ../../modules/user.nix
  ];

  general.enable = true;
  starship.enable = true;

  home.packages = with pkgs; [
    unstable.claude-code
  ];

  terminal = {
    enable = true;
    backend = "alacritty";
  };

  shell = {
    enable = true;
    backend = "bash";
  };

  sops-edit.enable = true;

  notifications.enable = true;

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
    userEmail = "birger.rydback@gmail.com";
  };

  services.ssh-agent = {
    enable = true;
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  programs.home-manager.enable = true;
}
