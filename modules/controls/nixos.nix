# System half of controls: users with tablet-mode screen rotation need to
# read input devices (the tablet-mode switch) through libinput.
{ config, lib, ... }:
with lib;

{
  config.users.users = mapAttrs (_: _: { extraGroups = [ "input" ]; }) (
    filterAttrs (
      _: u: u.my.controls.enable && u.my.controls.utils.enable && u.my.controls.utils.autoScreenRotation
    ) (config.home-manager.users or { })
  );
}
