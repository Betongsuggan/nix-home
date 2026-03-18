{ pkgs, config, lib, ... }:
with lib; {
  options.secrets = {
    enable = mkOption {
      description = "Enable secrets provider";
      type = types.bool;
      default = false;
    };

    keyProviders = mkOption {
      description = "List of environment secrets to expose";
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            description = "Name of the provider";
            type = types.str;
          };

          path = mkOption {
            description =
              "Path to executable providing an secret provider token to stdout when executed. Example: '$HOME/.config/openai/key_provider.sh'";
            type = types.str;
          };

          envVarName = mkOption {
            description =
              "Name of the environment variable to set (defaults to <NAME>_API_KEY)";
            type = types.str;
          };
        };
      });
      default = [ ];
    };
  };

  config = mkIf config.secrets.enable {

    home = {
      packages = map (provider:
        import ./keyProvider.nix {
          inherit pkgs;
          providerConfig = provider;
        }) config.secrets.keyProviders;

      sessionVariables = builtins.listToAttrs (map (provider: {
        name = provider.envVarName;
        value = "$(${provider.path})";
      }) config.secrets.keyProviders);
    };
  };
}
