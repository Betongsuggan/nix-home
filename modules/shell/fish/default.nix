{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

{
  config = mkIf config.my.shell.fish.enable {
    programs = {
      nix-index = mkIf config.my.shell.fish.enableNixIndex {
        enable = true;
        enableFishIntegration = true;
      };

      fish = {
        enable = true;
        shellAliases = config.my.shell.aliases;

        shellInit = ''
          export EDITOR="${config.my.shell.editor}"

          ${optionalString config.my.shell.viMode "fish_vi_key_bindings"}

          ${config.my.shell.fish.extraInit}
        '';
      };
    };
  };
}
