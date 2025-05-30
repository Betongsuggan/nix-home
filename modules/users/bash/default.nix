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
        cloud = "cd ~/Development/cloud";
        dashboard = "cd ~/Development/web/apps/dashboard";
        nocode = "cd ~/Development/web/apps/nocode";
        demo = "cd ~/Development/web/apps/nocode-demo";
        ll = "ls -la --color=auto";
        ls = "ls --color=auto";
        vim = "nvim";
        hm = "home-manager";
        gw = "./gradlew --no-daemon";
      };
      # PS1="\[\033[33m\]󰘧: \[\033[36m\]\W\[\033[00m\]> "
      #         
      initExtra = ''
        # include .profile if it exists
        [[ -f ~/.profile ]] && . ~/.profile

        set -o vi
        export EDITOR=nvim
        export PATH="$PATH:~/.cargo/bin/"
      '';
    };
  };
}
