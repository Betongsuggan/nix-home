{
  config,
  lib,
  inputs,
  ...
}:
with lib;

let
  # The Home Manager users with my.deck on: each gets the app password of
  # their Nextcloud account decrypted to /run/secrets/deck-token-<user>
  users = filterAttrs (_: u: u.my.deck.enable) (config.home-manager.users or { });
  vault = "${inputs.nix-vault}/secrets/common.yaml";
in
{
  config = mkIf (users != { }) {
    assertions = [
      {
        assertion = config.my.sops.enable;
        message = "my.deck: ${concatStringsSep ", " (attrNames users)} need the Deck token from the vault, but my.sops is off on this host";
      }
    ];

    sops.secrets = optionalAttrs (builtins.pathExists vault) (
      mapAttrs' (
        name: u:
        nameValuePair "deck-token-${name}" {
          sopsFile = vault;
          key = "accounts/nextcloud/${u.my.deck.user}/deck-token";
          owner = name;
          mode = "0400";
        }
      ) users
    );
  };
}
