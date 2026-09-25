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
}
