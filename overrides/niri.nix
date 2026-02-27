{ inputs }:
(final: prev: {
  niri-stable = inputs.niri.packages.${prev.system}.niri-stable.overrideAttrs (oldAttrs: {
    doCheck = false;
  });
})
