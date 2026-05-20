{ config, lib, pkgs, ... }:

with lib;

let cfg = config.git-server;
in {
  options.git-server = {
    enable = mkEnableOption "Minimal SSH-based git server (git-shell, no web UI)";

    user = mkOption {
      type = types.str;
      default = "git";
      description = "System user that owns the repositories and accepts SSH connections.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/git";
      description = "Directory holding the bare repositories (also the git user's home).";
    };

    repositories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "myrepo" ];
      description = ''
        Names of bare repositories to create under `dataDir`. Each entry "foo" results in
        a bare repo at `<dataDir>/foo.git`, clonable as `git@<host>:foo.git`.
        Existing repositories are left untouched.
      '';
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ssh-ed25519 AAAA... user@host" ];
      description = "SSH public keys allowed to push/pull as the git user.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = cfg.dataDir;
      createHome = true;
      shell = "${pkgs.git}/bin/git-shell";
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
      description = "git-shell user for the git-server module";
    };

    users.groups.${cfg.user} = { };

    environment.systemPackages = [ pkgs.git ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.user} -"
    ];

    systemd.services.git-server-init = {
      description = "Initialize bare git repositories for git-server";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.user;
        RemainAfterExit = true;
      };
      script = concatMapStringsSep "\n" (repo: ''
        if [ ! -d "${cfg.dataDir}/${repo}.git" ]; then
          ${pkgs.git}/bin/git init --bare "${cfg.dataDir}/${repo}.git"
        fi
      '') cfg.repositories;
    };
  };
}
