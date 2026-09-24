{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.communication = {
    enable = mkEnableOption "Enable communication tooling";
  };

  config = mkIf config.my.communication.enable {
    home.packages = with pkgs; [
      slack
    ];
  };
}
