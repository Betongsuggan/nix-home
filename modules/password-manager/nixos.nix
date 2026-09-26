{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

{
  # Bitwarden's "unlock with system authentication" asks polkit for its
  # action, and polkit only reads actions from the system profile: install
  # the policy (not the app) system-wide
  config = mkIf (inputs.self.lib.anyHomeUser config (u: u.my.password-manager.enable)) {
    environment.systemPackages = [
      (pkgs.runCommand "bitwarden-polkit-policy" { } ''
        install -Dm444 -t $out/share/polkit-1/actions \
          ${pkgs.bitwarden-desktop}/share/polkit-1/actions/com.bitwarden.Bitwarden.policy
      '')
    ];
  };
}
