{ config, lib, ... }:
with lib;

{
  options.my.wayland-security = {
    enable = mkEnableOption "Wayland security configuration";
  };

  config = mkIf config.my.wayland-security.enable {
    security.polkit.enable = true;
    programs.hyprlock.enable = true;
    # PAM service for swaylock (used by niri/sway). The stock NixOS stack
    # keeps pam_env/faillock and refuses empty passwords; fingerprint unlock is
    # added automatically (fprintAuth defaults to services.fprintd.enable), as
    # "fingerprint OR password".
    security.pam.services.swaylock = { };
  };
}
