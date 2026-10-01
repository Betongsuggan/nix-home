# island-stationary's session layout, shared by both users (imported by
# user-betongsuggan.nix and user-gamer.nix): the single output and its mode.
#
# The BenQ EX3501R is a 3440x1440 ultrawide, but its EDID also advertises
# 3840x2160 (and other) modes the panel cannot display. Left unpinned, the
# catch-all `highres` rule picks the largest advertised mode and the session
# comes up at 3840x2160@59.94. Pinning the real panel mode is the fix.
#
# Keyed by `desc:` rather than a connector name: the panel reaches the GPU
# through the RTX 2070's USB-C (VirtualLink) port, which the kernel enumerates
# as the unnamed connector `Unknown-2` (see SPEC.md) — a name that carries no
# meaning and is tied to probe order, while the description is the panel's own
# identity. Hyprland matches a `desc:` prefix against `hyprctl monitors`'
# description field.
{ ... }:

{
  my.window-manager.monitors = {
    "desc:BNQ BenQ EX3501R H8J00188019" = {
      mode = {
        width = 3440;
        height = 1440;
        # The panel's 100 Hz mode, which reports as 99.982
        refresh = 99.982;
      };
      position = {
        x = 0;
        y = 0;
      };
      scale = 1;
    };
  };
}
