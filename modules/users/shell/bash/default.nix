{ config, lib, ... }:
with lib;

{
  config = mkIf config.shell.bash.enable {
    programs.bash = {
      enable = true;
      shellAliases = config.shell.aliases;
      
      initExtra = ''
        # Include .profile if it exists
        [[ -f ~/.profile ]] && . ~/.profile

        ${optionalString config.shell.viMode "set -o vi"}
        export EDITOR="${config.shell.editor}"
        export PATH="$PATH:${concatStringsSep ":" config.shell.extraPaths}"
        
        ${config.shell.bash.extraInit}
      '';
    };
  };
}