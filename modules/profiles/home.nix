# Home Manager defaults every user starts from, plus the `desktop` user
# profile (switched on for all users by the NixOS workstation profile).
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.profiles.desktop.enable =
    mkEnableOption "a graphical session: window manager, launcher, browser, file manager";

  config = mkMerge [
    {
      my = {
        general.enable = mkDefault true;
        git.enable = mkDefault true;
        shell.enable = mkDefault true;
        ssh.enable = mkDefault true;
        starship.enable = mkDefault true;
        terminal.enable = mkDefault true;
        theming.enable = mkDefault true;
      };
    }

    (mkIf config.my.profiles.desktop.enable {
      # The standard folders (Desktop, Documents, Downloads, Music, Pictures,
      # Videos, Templates, Public), written to user-dirs.dirs so every
      # XDG-aware app (browsers, Slack, file dialogs, the portal) uses them
      xdg.userDirs = {
        enable = mkDefault true;
        createDirectories = mkDefault true;
      };

      # Kept small: mpv (media), nvim (text) and `nix run` cover the rest.
      # zathura over Okular, which pulled in the KDE libraries (1.8 GiB vs
      # 0.5 GiB closure)
      home.packages = with pkgs; [
        imv
        zathura
      ];

      my = {
        chromium.enable = mkDefault true;
        communication.enable = mkDefault true;
        file-manager.enable = mkDefault true;
        launcher.enable = mkDefault true;
        window-manager.enable = mkDefault true;
      };
    })
  ];
}
