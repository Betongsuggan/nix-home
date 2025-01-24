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

  config = 
    let
      serverConfig = mkIf config.game-streaming.server.enable {

        services.sunshine = {
          enable = true;
          autoStart = true;
          openFirewall = true;
          capSysAdmin = true;
          settings = {
            sunshine_name = "betongsuggan station";
          };
        };
      };

      clientConfig = mkIf config.game-streaming.client.enable {
        environment.systemPackages = [ moonlight-qt ];
      };
    in
      serverConfig // clientConfig;
}
