{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

{
  # nix-gaming's low-latency PipeWire module (min quantum, the RT module,
  # pulse client request/quantum and node latency), maintained upstream
  imports = [ inputs.nix-gaming.nixosModules.pipewireLowLatency ];

  options.my.audio = {
    enable = mkEnableOption "Enable sound hardware";
    lowLatency = mkEnableOption "Low-latency mode for gaming";
  };

  config = mkIf config.my.audio.enable {
    security.rtkit.enable = true;

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

      # nix-gaming's defaults: 48 kHz, quantum 64. Its ALSA-level overrides
      # stay off: forcing S32LE and a rate breaks HDMI sinks
      lowLatency.enable = config.my.audio.lowLatency;
    };

    environment.systemPackages = with pkgs; [
      pavucontrol
      libfreeaptx
    ];

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
