{ inputs }:
(final: prev: {
  niri-stable = inputs.niri.packages.${prev.stdenv.hostPlatform.system}.niri-stable.overrideAttrs (oldAttrs: {
    doCheck = false;
  });
})
