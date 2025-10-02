{ config, pkgs, ... }:

{
  home.username = "gamer";
  home.homeDirectory = "/home/gamer";
  home.stateVersion = "25.05";

  home.packages = [ pkgs.steam ];

  # Steam Big Picture Mode autostart service
  systemd.user.services.steam-bigpicture = {
    Unit = {
      Description = "Steam Big Picture Mode";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.steam}/bin/steam -bigpicture";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = "DISPLAY=:0";
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # XDG directory configuration
  #xdg = {
  #  mimeApps.enable = true;
  #  userDirs = {
  #    enable = true;
  #    createDirectories = true;
  #    documents = "$HOME/documents";
  #    download = "$HOME/downloads";
  #    music = "$HOME/media/music";
  #    pictures = "$HOME/media/images";
  #    videos = "$HOME/media/videos";
  #    desktop = "$HOME/other/desktop";
  #    publicShare = "$HOME/other/public";
  #    templates = "$HOME/other/templates";
  #    extraConfig = { XDG_DEV_DIR = "$HOME/dev"; };
  #  };
  #};

  programs.home-manager.enable = true;
}

