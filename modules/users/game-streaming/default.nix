{ pkgs, config, lib, ... }:
with lib;

{
  options.game-streaming = {
    server = {
      enable = mkOption {
        description = "Enable game streaming server";
        type = types.bool;
        default = false;
      };
    };
    client = {
      enable = mkOption {
        description = "Enable game streaming client";
        type = types.bool;
        default = false;
      };
    };
  };

  config =  {
    services.sunshine = mkIf config.game-streaming.server.enable {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = true;
      settings = {
        sunshine_name = "betongsuggan station";
      };
    };
    environment = mkIf config.game-streaming.client.enable {
      systemPackages = [ moonlight-qt ];
    };
  };

}
