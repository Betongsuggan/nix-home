# Home Manager defaults every user starts from, plus the `desktop` user
# profile (switched on for all users by the NixOS workstation profile).
{ config, lib, ... }:
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
        starship.enable = mkDefault true;
        terminal.enable = mkDefault true;
        theming.enable = mkDefault true;
      };
    }

    (mkIf config.my.profiles.desktop.enable {
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
