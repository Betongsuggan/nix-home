{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.br.bash;
in {
  options.br.bash = {
    enable = mkOption {
      description = "Enable bash shell";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) {
    programs.bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la --color=auto";
        ls = "ls --color=auto";
        vim = "nvim";
        hm = "home-manager";
        gw = "./gradlew --no-daemon";
        btop = "bpytop";
      };
      initExtra = ''
        set -o vi
        PS1="\[\033[33m\]ﬦ: \[\033[36m\]\W\[\033[00m\]> "
      '';
    };
  };
}
