# Every overlay applied to the fleet's nixpkgs, in order.
inputs: [
  inputs.nur.overlays.default
  (import ./flake-inputs.nix inputs)
  (import ./unstable.nix inputs)
  (import ./aws-cdk.nix)
  (import ./niri.nix inputs)
]
