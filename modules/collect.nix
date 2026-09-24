# `modules/<name>/<file>` for every module directory that has `<file>`.
# Adding a module is just creating its directory: nothing to register.
file:
let
  entries = builtins.readDir ./.;
  hasFile = name: entries.${name} == "directory" && builtins.pathExists (./. + "/${name}/${file}");
in
map (name: ./. + "/${name}/${file}") (builtins.filter hasFile (builtins.attrNames entries))
