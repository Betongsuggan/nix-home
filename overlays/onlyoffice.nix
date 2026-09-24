# See the nixpkgs-onlyoffice input comment in flake.nix. The upstream NixOS
# module derives x2t and x2t-with-fonts-and-themes from this package's
# passthru, so overriding onlyoffice-documentserver alone swaps the whole
# closure to the pinned (cached, working) build.
inputs: final: prev: {
  onlyoffice-documentserver =
    (import inputs.nixpkgs-onlyoffice {
      system = prev.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    }).onlyoffice-documentserver;
}
