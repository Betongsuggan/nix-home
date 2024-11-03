{ pkgs, config, lib, ... }:
with lib;
let 
  colors = import ./colors.nix;
  font = import ./font.nix;
in
{
  options.theme.name  = mkOption {
    description = "Choose theme to enable. Default is gruvbox";
    type = types.string;
    default = "gruvbox";
  };

  config.theme = {
    colors = colors.gruvbox;
    font = font.gruvbox;
    cornerRadius = "5px";
  };
}
