{ config, lib, pkgs, profile, ... }:
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = profile.user;
  home.homeDirectory = "/home/${profile.user}";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.05";

  fonts.fontconfig.enable = true;

  imports = [
    ./programs/autorandr
    ./programs/i3
    ./programs/neovim
    ./programs/picom
    ./programs/polybar
    ./programs/rofi
    ./programs/x11
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    skypeforlinux
    glibcLocales
    xorg.setxkbmap
    xorg.libXft
    rxvt-unicode-unwrapped

    # Display Management
    brightnessctl
    i3lock-fancy-rapid

    # Audio
    pavucontrol

    # Development
    altair
    adoptopenjdk-hotspot-bin-15
    awscli2
    docker-compose
    gnumake
    jetbrains.idea-ultimate
    jq
    kotlin
    newman
    nodejs
    postman

    # Games
    steam
    retroarch
    lutris
    chiaki
    antimicroX
    mangohud
    discord

    # Utilities
    ag
    chromium
    exfat
    feh
    gimp
    gitAndTools.diff-so-fancy
    gnome3.gedit
    gparted
    gthumb
    htop
    kazam
    kdenlive
    lm_sensors
    nerdfonts
    p7zip
    rofi
    tor-browser-bundle-bin
    unzip
    xfce.thunar

    # Communication
    slack
    teams
    zoom-us
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    BROWSER = "firefox";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo.outPath}/share/terminfo";
    JAVA_HOME = "${pkgs.adoptopenjdk-hotspot-bin-15}";
  };

  programs.bash = import ./programs/bash;
  elemental.home.programs.neovim.enable = true;

  xsession.enable = true;

  services.network-manager-applet.enable = true;
  programs.git = {
    enable = true;
    userEmail = profile.mail;
    userName = profile.name;

    extraConfig.core.pager = "diff-so-fancy | less --tabs=4 -RFX";

    aliases = {
      "f" = "fetch -pt";
      "s" = "status";
      "d" = "diff";
      "dn" = "diff --name-only";
      "co" = "checkout";
      "br" = "checkout -b";
      "r"  = "rebase";

      # Commits, additions, and modifications
      "cm" = "commit -m";
      "ca" = "commit --amend";
      "aa" = "add .";
      "au" = "add -u";
      "rh" = "reset --hard";
      "p"  = "push";
      "fp"  = "push --force-with-lease";

      # Logging
      "lgo" = "log --oneline --graph";
      "lo" = "log --oneline";
      "ln" = "log -n"; # follow with a number to show n logs
      "lon" = "log --oneline -n"; # follow with a number to show n logs
      "tree" = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
    };
  };

  systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [ "network.target" "sound.target" ];
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };
}
