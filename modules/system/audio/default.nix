{ config, lib, pkgs, ... }:
with lib;

{
  options.audio = { enable = mkEnableOption "Enable sound hardware"; };

  config = mkIf config.audio.enable {
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      wireplumber = {
        enable = true;
        extraConfig.bluetoothEnhancements = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.codecs" = [
              "sbc"
              "sbc_xq"
              "aac"
              "ldac"
              "aptx"
              "aptx_hd"
              "aptx_ll"
              "aptx_ll_duplex"
              "aptx_adaptive"
            ];
          };
        };
      };
      pulse.enable = true;
    };

    # Audio control utility available system-wide
    environment.systemPackages = with pkgs; [ pavucontrol libfreeaptx ];

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
