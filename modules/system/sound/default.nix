{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.sound;
in
{
  options.br.sound = {
    enable = mkEnableOption "Enable sound hardware";
  };

  config = mkIf cfg.enable {
    sound.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      wireplumber.enable = true;
      pulse.enable = true;
    };
    #hardware.pulseaudio = {
    #  enable = true;
    #  package = pkgs.pulseaudioFull;
    #  #extraModules = [ pkgs.pulseaudio-modules-bt ];
    #  support32Bit = true;
    #  daemon.config = {
    #    default-sample-format = "s24le";
    #    default-sample-rate = "44100";
    #  };
    #};
  };
}
