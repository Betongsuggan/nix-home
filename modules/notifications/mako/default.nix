{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.notifications;

in
{
  options.my.notifications.mako = {
    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Mako configuration";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "mako") {
    # Colors and font from the theme via stylix
    stylix.targets.mako.enable = true;
    services.mako = {
      enable = true;
      inherit (cfg.mako) settings;
    };
  };
}
