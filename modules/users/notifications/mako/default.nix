{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.notifications;

in {
  options.notifications.mako = {
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Mako configuration";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "mako") {
    services.mako = {
      enable = true;
      # TODO: Add mako-specific configuration
      # Can be added later when needed
    };
  };
}