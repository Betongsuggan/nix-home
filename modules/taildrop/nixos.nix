{
  config,
  lib,
  inputs,
  ...
}:
with lib;

let
  # The Home Manager users with my.taildrop on; one becomes the operator
  users = attrNames (filterAttrs (_: u: u.my.taildrop.enable) (config.home-manager.users or { }));
in
{
  config = mkIf (inputs.self.lib.anyHomeUser config (u: u.my.taildrop.enable)) {
    assertions = [
      {
        assertion = length users == 1;
        message = "my.taildrop: tailscale has one operator per host, but ${concatStringsSep ", " users} enable it";
      }
    ];

    # `tailscale file get` needs root or the operator; this lets the user's
    # receiver collect files without sudo
    services.tailscale.extraSetFlags = [ "--operator=${head users}" ];
  };
}
