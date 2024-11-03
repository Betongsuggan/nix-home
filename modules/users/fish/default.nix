{ pkgs, config, lib, ... }:
with lib;

{
  options.fish = {
    enable = mkOption {
      description = "Enable fish shell";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.fish.enable {
    home-manager.users.${config.user}.programs.fish = {
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
      initExtra = ''
        # include .profile if it exists
        [[ -f ~/.profile ]] && . ~/.profile

        set -o vi
        PS1="\[\033[33m\]󰘧: \[\033[36m\]\W\[\033[00m\]> "
        export EDITOR=nvim
        export PATH="$PATH:~/.cargo/bin/"
        export ANTHROPIC_API_KEY="$(ai_key_provider)"
      '';
    };
  };
}
