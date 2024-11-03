{ config, lib, pkgs, ... }:
with lib;
let 
  colors = import ./colors.nix;
  font = import ./font.nix;
in
{
  options.theme = {
    colors = mkOption {
      description = "Choose color theme to enable. Default is gruvbox";
      type = types.attrs;
      default = colors.gruvbox;
    };
    font = mkOption {
      description = "Choose font to enable. Default is hasklug";
      type = types.attrs;
      default = font.hasklug;
    };
    cornerRadius = mkOption {
      description = "Choose corner radius for windows. Default is 5";
      type = types.string;
      default = "5px";
    };
  };
}
