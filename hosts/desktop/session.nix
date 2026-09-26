# desktop's session layout, shared by both users (imported by
# user-betongsuggan.nix and user-gamer.nix): outputs, workspace placement and
# idle behavior.
#
# - DP-2: the PC monitor, primary; workspaces 1-9 live here
# - HDMI-A-2: the TV. HDMI stays "connected" while the TV is off, so it is
#   always an output; it only ever holds workspace 11 until something is moved
#   there (Mod+Ctrl+Shift+H/L moves a window across, Mod+Ctrl+H/L focuses it)
# - DP-1: an empty connector the kernel forces on with a generated EDID
#   (system.nix), because amdgpu needs a connected output to start with the
#   monitors off. Hyprland never uses it.
# The gamer session adds the SUNSHINE streaming output (user-gamer.nix).
{ lib, ... }:
let
  hdr = {
    bitdepth = 10;
    hdr = true;
    sdrBrightness = 1.0;
    sdrSaturation = 1.5;
  };
in
{
  my.window-manager = {
    # One idle suspend for the host: logind's IdleAction (system.nix, 30 min).
    # A second one from the compositor (15 min) would cut a gamepad-only
    # stream short, since gamepad input doesn't reach it; a running stream
    # also holds a sleep inhibitor (game-streaming).
    idle.suspendAfter = null;

    monitors = {
      DP-2 = hdr // {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 240;
        };
        position = {
          x = 0;
          y = 0;
        };
      };
      HDMI-A-2 = hdr // {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 120;
        };
        scale = 2;
        # right of the PC monitor
        position = {
          x = 3440;
          y = 0;
        };
      };
      DP-1.enable = false;
    };

    workspaceBindings =
      map (n: {
        workspace = n;
        monitor = "DP-2";
        default = n == 1;
      }) (lib.range 1 9)
      ++ [
        {
          workspace = 11;
          monitor = "HDMI-A-2";
          default = true;
        }
      ];
  };
}
