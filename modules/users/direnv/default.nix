{ config, lib, ... }:
with lib;

{
  options.direnv = {
    enable = mkEnableOption "Enable direnv for per-directory environment management";
  };

  config = mkIf config.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true; # Better nix integration with caching
    };
  };
}
