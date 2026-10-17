# Packages taken as-is from other flakes' `packages.<system>.default`.
inputs: final: prev:
let
  fromInput = input: input.packages.${prev.stdenv.hostPlatform.system}.default;
in
{
  awscli-local = fromInput inputs.awscli-local;
  walker = fromInput inputs.walker;
  elephant = fromInput inputs.elephant;
  audiomenu = fromInput inputs.audiomenu;
  monitormenu = fromInput inputs.monitormenu;
  console-mode = fromInput inputs.console-mode;
  nvim-config = fromInput inputs.nvim; # nixvim build, provides `nvim`

  # Static site: run the guide's stdlib-only Python build inside the sandbox
  # and keep only what nginx serves. Not reproducible to the byte (the footer
  # stamps the build date); harmless.
  wow-guide =
    prev.runCommand "wow-guide"
      {
        nativeBuildInputs = [ prev.python3 ];
        src = inputs.wow-guide;
      }
      ''
        cp -r "$src" site
        chmod -R u+w site
        cd site
        python3 build.py
        mkdir -p "$out"
        cp index.html level-*.html guide.css guide.js "$out"/
        cp -r maps "$out"/maps
      '';
}
