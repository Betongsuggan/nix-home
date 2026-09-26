{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib;

{
  options.my.password-manager.enable = mkOption {
    type = types.bool;
    default = config.my.profiles.desktop.enable && elem config.home.username osConfig.my.common.admins;
    defaultText = literalMD "an admin (`my.common.admins`) with the desktop profile";
    description = ''
      The Bitwarden desktop app. It unlocks with system authentication (the
      fingerprint or the password, through polkit) and unlocks the Firefox
      and Chromium extensions through browser integration.
    '';
  };

  config = mkIf config.my.password-manager.enable {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
