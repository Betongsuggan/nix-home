{ pkgs, config, lib, ... }:
with lib;

#let 
#  sessionVariables = builtins.concatStringsSep "\n" (mapAttrsToList (name: value: 
#  let 
#    valueWithEnvHome = lib.replaceStrings [ "$HOME" ] [ "$env.HOME" ] value;
#  in
#  ''
#    $env.${name} = $env.${name} + ":" + ${valueWithEnvHome};
#  '') config.home.sessionVariables);
#in
{
  options.nushell = {
    enable = mkOption {
      description = "Enable nushell";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.nushell.enable {
    programs.nushell = {
      enable = true;
      configFile = { 
        text = ''
          $env.config = {
            show_banner: false
            edit_mode: vi
          }

        '';
      };
      envFile = {
        text = "";
      };
      shellAliases = {
        cloud = "cd ~/Development/cloud";
        dashboard = "cd ~/Development/web/apps/dashboard";
        nocode = "cd ~/Development/web/apps/nocode";
        demo = "cd ~/Development/web/apps/nocode-demo";
        ll = "ls -la";
        vim = "nvim";
        hm = "home-manager";
        gw = "./gradlew --no-daemon";
      };
      #importSessionVariables = true;
      #initExtra = ''
      #  # include .profile if it exists
      #  [[ -f ~/.profile ]] && . ~/.profile

      #  set -o vi
      #  PS1="\[\033[33m\]󰘧: \[\033[36m\]\W\[\033[00m\]> "
      #  export EDITOR=nvim
      #  export PATH="$PATH:~/.cargo/bin/"
      #  export ANTHROPIC_API_KEY="$(ai_key_provider)"
      #'';
    };
  };
}
