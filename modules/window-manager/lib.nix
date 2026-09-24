# Helpers shared by the window-manager backends
{ lib }:
rec {
  # 1 -> "1", 1.5 -> "1.5", 1.0 -> "1.0" (toString would give "1.000000")
  fmtNum =
    n:
    if builtins.isInt n then
      toString n
    else
      let
        m = builtins.match "(-?[0-9]+)[.]([0-9]*[1-9])?0*" (toString n);
      in
      "${builtins.elemAt m 0}.${if builtins.elemAt m 1 == null then "0" else builtins.elemAt m 1}";

  toFloat = n: n * 1.0;

  # Named outputs of my.window-manager.monitors, as a list of { name, ... }
  outputList = monitors: lib.mapAttrsToList (name: m: m // { inherit name; }) monitors;
}
