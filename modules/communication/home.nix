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
    discord = mkEnableOption "Discord (on by default via the games module on gaming hosts)";
  };

  config = mkIf config.my.communication.enable {
    home.packages = with pkgs; [ slack ] ++ optional config.my.communication.discord discord;
  };
}
