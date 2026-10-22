{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.restic-backup;
  selfLib = inputs.self.lib;

  # A sleeping target is woken before each run and the run waits for its SSH
  # port: directly when this host is the target's WoL relay (registry
  # `hosts.<target>.wol.relay`), otherwise through the relay's `wake` account
  # (modules/common), which accepts this host's restic key for exactly that
  wakeCommand =
    name: target:
    let
      wol = selfLib.hosts.${name}.wol or null;
      relay = wol.relay or null;
      port = "/dev/tcp/${target.sftpHost}/22";
      wake =
        if relay == config.my.common.host then
          "${pkgs.wakeonlan}/bin/wakeonlan ${wol.mac}"
        else
          "${pkgs.openssh}/bin/ssh -i ${cfg.sshKeyFile} -o BatchMode=yes -o StrictHostKeyChecking=yes wake@${selfLib.tailnet.fqdn relay} wake-${name}";
    in
    if wol != null && relay != null && wol.mac != "00:00:00:00:00:00" then
      ''
        up() { ${pkgs.coreutils}/bin/timeout 3 ${pkgs.bash}/bin/bash -c "< ${port}" 2>/dev/null; }
        up && exit 0
        ${wake}
        for _ in $(${pkgs.coreutils}/bin/seq 150); do
          up && exit 0
          ${pkgs.coreutils}/bin/sleep 2
        done
        echo "${name} did not wake up" >&2
        exit 1
      ''
    else
      null;

  # The weekly proof that a repo is usable: the latest snapshot is recent, and
  # one path restores and verifies against the repo's hashes. `restic-<name>`
  # is the wrapper the upstream module installs (repo, password, SFTP args).
  verifyScript =
    name: target:
    let
      restic = "/run/current-system/sw/bin/restic-${name}";
      wake = wakeCommand name target;
    in
    pkgs.writeShellScript "restic-verify-${name}" ''
      set -euo pipefail
      ${optionalString (wake != null) "( ${wake} ) || exit 1"}
      latest=$(${restic} snapshots --latest 1 --json | ${pkgs.jq}/bin/jq -r '.[0].time // empty')
      [ -n "$latest" ] || { echo "restic ${name}: no snapshots" >&2; exit 1; }
      age=$(( ($(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/date -d "$latest" +%s)) / 86400 ))
      [ "$age" -le ${toString cfg.verify.maxSnapshotAgeDays} ] \
        || { echo "restic ${name}: latest snapshot is $age days old" >&2; exit 1; }
      tmp=$(${pkgs.coreutils}/bin/mktemp -d /var/lib/restic/verify-${name}.XXXXXX)
      trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
      ${restic} restore latest --verify --target "$tmp" --path ${escapeShellArg cfg.verify.restorePath}
      n=$(${pkgs.findutils}/bin/find "$tmp" -type f | ${pkgs.coreutils}/bin/wc -l)
      [ "$n" -gt 0 ] || { echo "restic ${name}: restore of ${cfg.verify.restorePath} produced no files" >&2; exit 1; }
      echo "restic ${name}: snapshot $age days old, $n files restored and verified from ${cfg.verify.restorePath}"
    '';
in
{
  options.my.restic-backup = {
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
      example = [
        "**/.cache/**"
        "**/.thumbnails/**"
      ];
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
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              hostKey = mkOption {
                type = types.nullOr types.str;
                default = inputs.self.lib.hosts.${name}.ssh.host or null;
                defaultText = literalExpression "inputs.self.lib.hosts.<name>.ssh.host or null";
                description = ''
                  The receiver's SSH host public key. SFTP connections then check
                  the host strictly against it. Defaults to the key recorded in the
                  lib host registry for a target named after a fleet host. `null`
                  falls back to trust-on-first-use (`accept-new`).
                '';
              };
              sftpHost = mkOption {
                type = types.str;
                default = inputs.self.lib.tailnet.fqdn name;
                defaultText = literalExpression "lib.tailnet.fqdn <name>";
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
          }
        )
      );
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

    verify = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Prove the backups are usable: every run ends with `restic check`
          reading `readDataSubset` of the repo, and a weekly job asserts the
          latest snapshot is at most `maxSnapshotAgeDays` old and restores
          `restorePath` into a scratch dir with content verification.
        '';
      };
      onCalendar = mkOption {
        type = types.str;
        default = "weekly";
        description = "systemd OnCalendar expression for the restore test.";
      };
      readDataSubset = mkOption {
        type = types.str;
        default = "2%";
        description = "`restic check --read-data-subset` argument run after every backup; 2% a day reads the whole repo in about seven weeks.";
      };
      maxSnapshotAgeDays = mkOption {
        type = types.int;
        default = 2;
        description = "The restore test fails when the latest snapshot is older than this.";
      };
      restorePath = mkOption {
        type = types.path;
        default = head cfg.paths;
        defaultText = literalExpression "head cfg.paths";
        description = "The path the weekly restore test restores. Keep it small.";
      };
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
        backupPrepareCommand = wakeCommand name target;
        extraBackupArgs = concatMap (p: [
          "--exclude"
          p
        ]) cfg.excludes;
        extraOptions = [
          (
            let
              hostKeyArgs =
                if target.hostKey != null then
                  "-o StrictHostKeyChecking=yes -o UserKnownHostsFile=${pkgs.writeText "restic-${name}-known-hosts" "${target.sftpHost} ${target.hostKey}\n"}"
                else
                  "-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/var/lib/restic/known_hosts";
            in
            "sftp.args='-i ${cfg.sshKeyFile} ${hostKeyArgs}'"
          )
        ];
        pruneOpts = cfg.pruneOpts;
        runCheck = cfg.verify.enable;
        checkOpts = [ "--read-data-subset=${cfg.verify.readDataSubset}" ];
        timerConfig = {
          OnCalendar = cfg.timerOnCalendar;
          Persistent = true;
          RandomizedDelaySec = "30min";
        };
      }
    ) cfg.targets;

    systemd.services = mkIf cfg.verify.enable (
      mapAttrs' (
        name: target:
        nameValuePair "restic-verify-${name}" {
          description = "Restore test of the restic repo on ${name}";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = verifyScript name target;
          };
        }
      ) cfg.targets
    );
    systemd.timers = mkIf cfg.verify.enable (
      mapAttrs' (
        name: _:
        nameValuePair "restic-verify-${name}" {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.verify.onCalendar;
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        }
      ) cfg.targets
    );
  };
}
