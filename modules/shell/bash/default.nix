{ config, lib, ... }:
with lib;

{
  config = mkIf config.my.shell.bash.enable {
    programs.bash = {
      enable = true;
      shellAliases = config.my.shell.aliases;

      initExtra = ''
        # Include .profile if it exists
        [[ -f ~/.profile ]] && . ~/.profile

        ${optionalString config.my.shell.viMode "set -o vi"}
        export EDITOR="${config.my.shell.editor}"

        ${config.my.shell.bash.extraInit}
      '';
    };
  };
}
