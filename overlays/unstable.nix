# `pkgs.unstable.<name>` for the few packages wanted from nixos-unstable.
inputs: final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
}
