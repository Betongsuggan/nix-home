{ config, pkgs, lib, ... }:
{
  options.neovim = {
    enable = lib.mkEnableOption "Enable the vim editor";
  };

  config = lib.mkIf config.neovim.enable {

    home-manager.users.${config.user}.home.packages = [
      pkgs.neovim
    ];
  };
}
