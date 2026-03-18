{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.communication = {
    enable = mkEnableOption "Enable communication tooling";
  };

  config = mkIf config.communication.enable {
    home.packages = with pkgs; [
      slack
    ];
  };
}
