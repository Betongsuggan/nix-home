{ pkgs, inputs, ... }:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    unstable.claude-code
  ];

  my.sops.enable = true;
  #chromium.enable = true;
  #notifications.enable = true;

  #launcher = {
  #  enable = true;
  #  backend = "vicinae";
  #  vicinae = {
  #    extensions = with pkgs; [
  #      vicinae-wifi-commander
  #      vicinae-bluetooth
  #      vicinae-monitor
  #    ];
  #  };
  #};

  #windowManager = {
  #  enable = true;
  #  backend = "niri";
  #  composeKey = "ralt";
  #};

}
