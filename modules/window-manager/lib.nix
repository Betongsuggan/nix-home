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
  # A wl_output transform number in sway's and niri's spelling
  transformName =
    t:
    builtins.elemAt [
      "normal"
      "90"
      "180"
      "270"
      "flipped"
      "flipped-90"
      "flipped-180"
      "flipped-270"
    ] t;

  outputList = monitors: lib.mapAttrsToList (name: m: m // { inherit name; }) monitors;

  # "Mod+Ctrl+P" -> { mods = [ "Mod" "Ctrl" ]; key = "P"; }
  chord =
    c:
    let
      parts = lib.splitString "+" c;
    in
    {
      mods = lib.init parts;
      key = lib.last parts;
    };

  # How a keymap entry is run on `backend`: its shell command (spawn, as one
  # string) or the backend's native action; null = leave unbound
  spawnString = s: if builtins.isList s then lib.concatStringsSep " " s else s;
  entryFor =
    backend: e:
    if e ? spawn then
      (if e.spawn == null then null else { spawn = e.spawn; })
    else if (e.${backend} or null) != null then
      { native = e.${backend}; }
    else
      null;

  # The keymap as i3/sway `keybindings` (both share the syntax)
  i3Keybindings =
    backend: modifier: keybinds:
    let
      modName = {
        Mod = modifier;
        Ctrl = "Ctrl";
        Shift = "Shift";
        Alt = "Mod1";
      };
      keyName = {
        Space = "space";
        Minus = "minus";
        Equal = "equal";
        Comma = "comma";
        Period = "period";
      };
    in
    lib.concatMapAttrs (
      chordName: e:
      let
        c = chord chordName;
        how = entryFor backend e;
        key = keyName.${c.key} or (if lib.stringLength c.key == 1 then lib.toLower c.key else c.key);
      in
      lib.optionalAttrs (how != null) {
        ${lib.concatStringsSep "+" (map (m: modName.${m}) c.mods ++ [ key ])} =
          if how ? spawn then "exec ${spawnString how.spawn}" else how.native;
      }
    ) keybinds;
}
