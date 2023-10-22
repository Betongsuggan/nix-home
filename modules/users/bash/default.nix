{ pkgs, config, lib, ... }:
with lib;

{
  options.bash = {
    enable = mkOption {
      description = "Enable bash shell";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.bash.enable {
    home-manager.users.${config.user}.programs.bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la --color=auto";
        ls = "ls --color=auto";
        vim = "nvim";
        hm = "home-manager";
        gw = "./gradlew --no-daemon";
      };
      initExtra = ''
        set -o vi
        PS1="\[\033[33m\]󰘧: \[\033[36m\]\W\[\033[00m\]> "
        export EDITOR=nvim
      '';
    };
  };
}
