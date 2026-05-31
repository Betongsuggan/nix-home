{ config, lib, pkgs, ... }:

with lib;

let cfg = config.restic-backup;
in {
  options.restic-backup = {
    enable = mkEnableOption "Push-mode restic backups to one or more SFTP targets";

    paths = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Paths on this host to include in every backup job. The same set is
        pushed to every configured target.
      '';
    };

    excludes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "**/.cache/**" "**/.thumbnails/**" ];
      description = ''
        Restic exclude patterns. Each entry becomes a `--exclude <pattern>`
        argument on the backup command line.
      '';
    };

    passwordFile = mkOption {
      type = types.path;
      description = ''
        Path to a file containing the restic repository password. Typically a
        sops-nix decrypted file. The same password is reused across all
        configured targets — each target is a separate repo but uses one
        password for operational simplicity.
      '';
    };

    sshKeyFile = mkOption {
      type = types.path;
      description = ''
        Path to the private SSH key used to authenticate against every target's
        SFTP user. Typically a sops-nix decrypted file. Public half must be
        registered under `hosts.<this-host>.users.restic.ssh.<name>` in
        `lib/default.nix`, never as a literal in the host configuration.
      '';
    };

    targets = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          sftpHost = mkOption {
            type = types.str;
            example = "desktop.ts.rydback.net";
            description = "Hostname of the SFTP receiver (typically the tailnet FQDN).";
          };
          sftpUser = mkOption {
            type = types.str;
            example = "restic-controller";
            description = ''
              Username on the receiver. Convention: `restic-<source-host>`, so
              this should match the corresponding entry on the receiver's
              `restic-target.sources.<source>` configuration.
            '';
          };
          sftpPath = mkOption {
            type = types.path;
            default = "/repo";
            description = ''
              Path to the restic repository as seen by the SFTP server **inside
              the receiver's chroot**. The default `/repo` matches the writable
              subdir created by `restic-target` (the chroot root itself is
              root-owned 0755 and not writable — see that module's SPEC).
            '';
          };
        };
      });
      default = { };
      description = ''
        Named SFTP targets. One `services.restic.backups.<name>` job is
        generated per attribute. Attribute name becomes the systemd unit
        suffix (`restic-backups-<name>.service`).
      '';
    };

    timerOnCalendar = mkOption {
      type = types.str;
      default = "daily";
      description = "systemd OnCalendar expression for the backup schedule.";
    };

    pruneOpts = mkOption {
      type = types.listOf types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      description = ''
        Restic `forget --prune` options applied after each successful backup.
        Retention policy applies independently to each target repo.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/restic 0700 root root -"
    ];

    services.restic.backups = mapAttrs' (
      name: target:
      nameValuePair name {
        paths = cfg.paths;
        repository = "sftp:${target.sftpUser}@${target.sftpHost}:${target.sftpPath}";
        passwordFile = cfg.passwordFile;
        initialize = true;
        extraBackupArgs = concatMap (p: [ "--exclude" p ]) cfg.excludes;
        extraOptions = [
          "sftp.args='-i ${cfg.sshKeyFile} -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/var/lib/restic/known_hosts'"
        ];
        pruneOpts = cfg.pruneOpts;
        timerConfig = {
          OnCalendar = cfg.timerOnCalendar;
          Persistent = true;
          RandomizedDelaySec = "30min";
        };
      }
    ) cfg.targets;
  };
}
