# Fleet status, the NixOS half: the launcher flake's services.fleet-status
# (status server and announcements) fed from the registry.
{
  config,
  lib,
  inputs,
  ...
}:
with lib;

let
  cfg = config.my.fleet-status;
  selfLib = inputs.self.lib;
  self = config.my.common.host;
in
{
  imports = [ inputs.launcher.nixosModules.default ];

  options.my.fleet-status = {
    enable = mkOption {
      type = types.bool;
      default = config.services.tailscale.enable;
      defaultText = literalExpression "config.services.tailscale.enable";
      description = ''
        Serve this host's status (battery, disk, uptime, backups, running
        system, what peers last announced) as JSON on the tailnet, for the
        fleet dashboard, and accept peers' suspend/shutdown announcements.
      '';
    };

    announceTo = mkOption {
      type = types.nullOr types.str;
      default = selfLib.hosts.${self}.wol.relay or null;
      defaultText = literalMD "this host's WoL relay from the registry (`hosts.<host>.wol.relay`), if any";
      description = ''
        A host to tell before suspending or shutting down (and after
        resuming), so the dashboard can show "asleep" or "shut down" instead
        of tailscale's "offline". The natural choice is the host that wakes
        this one, which is always on while this one is not.
      '';
    };
  };

  config.services.fleet-status = {
    inherit (cfg) enable announceTo;
    hostName = self;
    port = selfLib.tailnet.statusPort;
    hosts = selfLib.fleetHosts { inherit self; };
  };
}
