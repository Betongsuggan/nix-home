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
      config.global.hide_env_diff = true;
    };

    programs.bash.sessionVariables = {
      DIRENV_LOG_FORMAT = ""; # Suppress direnv log output
    };
  };
}
