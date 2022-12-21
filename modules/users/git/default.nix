{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.br.git;
in {
  options.br.git = {
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

  config = mkIf (cfg.enable) {
    home.packages = [ pkgs.gitAndTools.diff-so-fancy ];
    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.userEmail;
      extraConfig = {
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        credential.helper = "${
            pkgs.git.override { withLibsecret = true; }
          }/bin/git-credential-libsecret";
      };
      aliases = {
        "f" = "fetch -pt";
        "s" = "status";
        "d" = "diff";
        "dn" = "diff --name-only";
        "co" = "checkout";
        "br" = "checkout -b";
        "r"  = "rebase";
 
        # Commits, additions, and modifications
        "cm" = "commit -m";
        "ca" = "commit --amend";
        "aa" = "add .";
        "au" = "add -u";
        "rh" = "reset --hard";
        "p"  = "push";
        "fp"  = "push --force-with-lease";
 
        # Logging
        "lgo" = "log --oneline --graph";
        "lo" = "log --oneline";
        "ln" = "log -n"; # follow with a number to show n logs
        "lon" = "log --oneline -n"; # follow with a number to show n logs
        "tree" = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
      };
    };
  };
}
