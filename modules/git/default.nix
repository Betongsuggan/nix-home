{ pkgs, config, lib, ... }:
with lib;

{
  options.git = {
    enable = mkOption {
      description = "Enable git";
      type = types.bool;
      default = false;
    };

    userName = mkOption {
      description = "Name for git";
      type = types.str;
      default = "Birger Rydback";
    };

    userEmail = mkOption {
      description = "Email for git";
      type = types.str;
      default = "birger@humla.io";
    };
  };

  config = mkIf config.git.enable {

    home.packages = [ pkgs.diff-so-fancy ];
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = config.git.userName;
          email = config.git.userEmail;
        };
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        credential.helper = "${pkgs.gitFull}/bin/git-credential-libsecret";
        url = {
          "ssh://git@github.com" = { insteadOf = "https://github.com"; };
        };
        push = { autoSetupRemote = true; };
        alias = {
          "f" = "fetch -pt";
          "s" = "status";
          "d" = "diff";
          "dn" = "diff --name-only";
          "co" = "checkout";
          "br" = "checkout -b";
          "r" = "rebase";

          # Commits, additions, and modifications
          "cm" = "commit -m";
          "ca" = "commit --amend";
          "aa" = "add .";
          "au" = "add -u";
          "rh" = "reset --hard";
          "p" = "push";
          "fp" = "push --force-with-lease";

          # Logging
          "lgo" = "log --oneline --graph";
          "lo" = "log --oneline";
          "ln" = "log -n"; # follow with a number to show n logs
          "lon" = "log --oneline -n"; # follow with a number to show n logs
          "tree" =
            "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
        };
      };
    };
  };
}
