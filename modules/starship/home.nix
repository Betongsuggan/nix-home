{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

{
  options.my.starship = {
    enable = mkOption {
      description = "Enable starship";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.my.starship.enable {
    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
  };
}
