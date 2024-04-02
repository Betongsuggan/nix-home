{ config, lib, pkgs, ... }:
with lib;

{
  options.audio = {
    enable = mkEnableOption "Enable sound hardware";
  };

  config = mkIf config.audio.enable {
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

    home-manager.users.${config.user} = {
      home.packages = [
        pkgs.pavucontrol
        pkgs.youtube-music
      ];
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
