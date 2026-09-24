{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

{
  config = mkIf config.my.shell.nushell.enable {
    programs.nushell = {
      enable = true;

      configFile = {
        text = ''
          $env.config = {
            show_banner: ${if config.my.shell.nushell.showBanner then "true" else "false"}
            edit_mode: ${if config.my.shell.viMode then "vi" else "emacs"}
          }

          ${config.my.shell.nushell.extraConfig}
        '';
      };

      envFile = {
        text = "";
      };

      shellAliases = config.my.shell.aliases;
    };
  };
}
