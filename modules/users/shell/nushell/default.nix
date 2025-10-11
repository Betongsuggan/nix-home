{ pkgs, config, lib, ... }:
with lib;

{
  config = mkIf config.shell.nushell.enable {
    programs.nushell = {
      enable = true;
      
      configFile = { 
        text = ''
          $env.config = {
            show_banner: ${if config.shell.nushell.showBanner then "true" else "false"}
            edit_mode: ${if config.shell.viMode then "vi" else "emacs"}
          }

          ${config.shell.nushell.extraConfig}
        '';
      };
      
      envFile = {
        text = "";
      };
      
      shellAliases = config.shell.aliases;
    };
  };
}