# Fleet status, the Home Manager half: the launcher flake's fleet dashboard
# (programs.launcher.fleet) with the registry's hosts and what this user may
# do on each of them.
{
  config,
  lib,
  inputs,
  osConfig,
  ...
}:
with lib;

let
  cfg = config.my.fleet-status.dashboard;
  selfLib = inputs.self.lib;
  self = osConfig.my.common.host;

  # The plug-<name> commands (modules/shelly-plug), when this host has them
  plugCommand =
    plug:
    if plug == null || !osConfig.my.shelly-plug.enable then
      null
    else
      "${osConfig.my.shelly-plug.package}/bin/plug-${plug}";
in
{
  options.my.fleet-status.dashboard = {
    enable = mkOption {
      type = types.bool;
      default = config.my.profiles.desktop.enable && elem config.home.username osConfig.my.common.admins;
      defaultText = literalMD "an admin (`my.common.admins`) with the desktop profile";
      description = "The fleet dashboard: every host's status, and SSH, wake, power and rebuild checks, in the launcher.";
    };
    flake = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/nix-home";
      description = "The nix-home checkout that \"Check if a rebuild is needed\" evaluates.";
    };
    package = mkOption {
      type = types.package;
      readOnly = true;
      default = config.programs.launcher.fleet.package;
      defaultText = literalExpression "config.programs.launcher.fleet.package";
      description = "The dashboard command (for keybinds: Mod+G in modules/window-manager).";
    };
  };

  config = mkIf cfg.enable {
    programs.launcher.fleet = {
      enable = true;
      inherit self;
      inherit (cfg) flake;
      hosts = selfLib.fleetHosts {
        inherit self plugCommand;
        user = config.home.username;
      };
    };
  };
}
