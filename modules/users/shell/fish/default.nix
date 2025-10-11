{ pkgs, config, lib, ... }:
with lib;

{
  config = mkIf config.shell.fish.enable {
    programs = {
      nix-index = mkIf config.shell.fish.enableNixIndex {
        enable = true;
        enableFishIntegration = true;
      };
      
      fish = {
        enable = true;
        shellAliases = config.shell.aliases;
        
        shellInit = ''
          export EDITOR="${config.shell.editor}"
          export PATH="$PATH:${concatStringsSep ":" config.shell.extraPaths}"
          export ANTHROPIC_API_KEY="$(ai_key_provider)"

          ${optionalString config.shell.viMode "fish_vi_key_bindings"}
          
          ${config.shell.fish.extraInit}
        '';
      };
    };
  };
}