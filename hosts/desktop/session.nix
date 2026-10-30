# desktop's session layout, shared by both users (imported by
# user-betongsuggan.nix and user-gamer.nix): outputs, workspace placement and
# idle behavior.
#
# - DP-2: the PC monitor, primary; starts on workspace 1 (Steam in gamer)
# - HDMI-A-2: the TV. HDMI stays "connected" while the TV is off, so it is
#   always an output; it starts on workspace 11. Mod+Ctrl+H/L focuses it, and
#   a workspace opened while it has focus lands there. Mod+Alt+H/L moves the
#   current workspace across (game on the TV), Mod+Ctrl+Shift+H/L one window
# - DP-1: an empty connector the kernel forces on with a generated EDID
#   (system.nix), because amdgpu needs a connected output to start with the
#   monitors off. Hyprland never uses it.
# The gamer session adds the SUNSHINE streaming output (user-gamer.nix).
{ ... }:
let
  # Both screens: HDR, 10-bit and VRR. Without VRR the top of DP-2 flickered
  # white in HDR (betongsuggan's session, 2026-09-26); gamer had it on and
  # never did
  hdr = {
    vrr = true;
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

    # Only each screen's default workspace is pinned: that alone keeps the TV
    # from taking 2, 3, ... when it appears. Other workspaces open on the
    # focused screen, and Mod+Alt+H/L carries a whole workspace across
    workspaceBindings = [
      {
        workspace = 1;
        monitor = "DP-2";
        default = true;
      }
      {
        workspace = 11;
        monitor = "HDMI-A-2";
        default = true;
      }
    ];
  };
}
