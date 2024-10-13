{ pkgs, config, lib, ... }:
let 
  keyProvider = import ./keyProvider.nix { inherit pkgs config;  };
in
with lib;

{
  options.ai = {
    enable = mkOption {
      description = "Enable AI provider secrets";
      type = types.bool;
      default = false;
    };

    keyProviderPath = mkOption {
      description = "Path to executable providing an AI provider token to stdout when executed. Example: '$HOME/.config/openai/key_provider.sh'";
      type = types.string;
    };
  };


  config = mkIf config.ai.enable {
    home-manager.users.${config.user} = {
      home = {
        packages = [
          keyProvider
        ];
      };
    };
  };
}
