{ pkgs, config, lib, ... }:
with lib;
{
  options.ai = {
    enable = mkOption {
      description = "Enable AI provider secrets";
      type = types.bool;
      default = false;
    };

    keyProviders = mkOption {
      description = "List of AI key providers";
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            description = "Name of the provider";
            type = types.string;
          };

          path = mkOption {
            description = "Path to executable providing an AI provider token to stdout when executed. Example: '$HOME/.config/openai/key_provider.sh'";
            type = types.string;
          };

          envVarName = mkOption {
            description = "Name of the environment variable to set (defaults to <NAME>_API_KEY)";
            type = types.str;
          };
        };
      });
      default = [ ];
    };
  };

  config = mkIf config.ai.enable {
    home-manager.users.${config.user} = {
      home = {
        packages = map
          (provider:
            import ./keyProvider.nix {
              inherit pkgs;
              providerConfig = provider;
            }
          )
          config.ai.keyProviders;

        sessionVariables = builtins.listToAttrs (map
          (provider: {
            name = provider.envVarName;
            value = "$(${provider.path})";
          })
          config.ai.keyProviders);
      };
    };
  };
}
