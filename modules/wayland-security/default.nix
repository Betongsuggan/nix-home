{ config, lib, ... }:
with lib;

{
  options.wayland-security = { enable = mkEnableOption "Wayland security configuration"; };

  config = mkIf config.wayland-security.enable {
    security.polkit.enable = true;
    programs.hyprlock.enable = true;
    # PAM configuration for swaylock (used by niri/sway)
    security.pam.services.swaylock = {
      # Use custom PAM rules to allow fingerprint OR password (not both required)
      text = lib.mkIf config.fingerprint.enable ''
        # Fingerprint authentication (sufficient = success here means authenticated)
        auth  sufficient  pam_fprintd.so
        # Password authentication (sufficient = fallback if fingerprint not used)
        auth  sufficient  pam_unix.so try_first_pass likeauth nullok
        # Deny if neither succeeded
        auth  required    pam_deny.so

        account required pam_unix.so

        password required pam_unix.so

        session required pam_unix.so
      '';
    };
  };
}
