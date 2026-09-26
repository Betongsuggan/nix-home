# Games, NixOS half: Steam itself, switched on when any Home Manager user on
# the host sets my.games.enable (the per-user config stays the single source).
#
# Steam is a NixOS concern: programs.steam builds the FHS wrapper with the GPU
# driver paths, adds the steam-hardware udev rules (controller access) and
# bakes STEAM_EXTRA_COMPAT_TOOLS_PATHS into the wrapper, so declarative
# compatibility tools (Proton-GE) show up in Steam's list. A Home Manager
# `steam` plus Proton-GE linked into ~/.steam does not work: nixpkgs'
# proton-ge-bin ships the tool only in its `steamcompattool` output, meant for
# programs.steam.extraCompatPackages. Remote Play firewall ports are the
# host's choice (programs.steam.remotePlay.openFirewall).
{
  config,
  lib,
  inputs,
  ...
}:
let
  users = lib.attrValues (config.home-manager.users or { });
  gaming = u: u.my.games.enable;
  anyGames = inputs.self.lib.anyHomeUser config gaming;
  gamers = lib.attrNames (lib.filterAttrs (_: gaming) (config.home-manager.users or { }));

  # Every gaming user's Proton-GE builds (each exposes `steamcompattool`)
  protonPackages = lib.unique (
    lib.concatMap (
      u: lib.optionals (gaming u && u.my.games.protonGE.enable) u.my.games.protonGE.packages
    ) users
  );
in
{
  # nix-gaming: programs.steam.platformOptimizations, the sysctls SteamOS
  # ships (vm.max_map_count, split-lock mitigation off, short TCP FIN
  # timeout, CFS bandwidth slice); hosts must not set vm.max_map_count too
  imports = [ inputs.nix-gaming.nixosModules.platformOptimizations ];

  config = lib.mkIf anyGames {
    programs.steam = {
      enable = true;
      extraCompatPackages = protonPackages;
      # Wrapped with the same compat-tool paths as Steam
      protontricks.enable = lib.any (u: gaming u && u.my.games.tools.enable) users;
      platformOptimizations.enable = true;
      # Steam Input's desktop-mode keyboard/mouse emulation uses X11 XTest,
      # which under a Wayland compositor only reaches XWayland clients.
      # extest, preloaded into Steam, turns it into uinput events the
      # compositor delivers like real hardware (steam-for-linux#13185)
      extest.enable = true;
    };

    # extest opens /dev/uinput as the Steam user
    hardware.uinput.enable = true;
    users.users = lib.genAttrs gamers (_: {
      extraGroups = [ "uinput" ];
    });
  };
}
