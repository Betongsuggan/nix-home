{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.restic-target;
  sourceNames = attrNames cfg.sources;
in {
  options.restic-target = {
    enable = mkEnableOption "Receive restic backups from one or more sources over chrooted SFTP";

    sources = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              sshKey = mkOption {
                type = types.str;
                example = literalExpression "inputs.self.lib.hosts.controller.users.restic.ssh.id_ed25519";
                description = ''
                  The source host's restic public key. **Always** pull this from
                  `inputs.self.lib.hosts.<source>.users.restic.ssh.<keyname>` —
                  never paste a literal here. Adding a new source then means
                  one edit to `lib/default.nix`, not edits in every receiver.
                '';
              };

              storagePath = mkOption {
                type = types.path;
                default = "/var/lib/restic-repos/${name}";
                description = ''
                  Filesystem path that holds the restic repo for this source.
                  This path is the SFTP chroot root and must therefore be
                  root-owned (sshd refuses to chroot into a user-writable dir).
                  The actual writable repo lives at `<storagePath>/repo`.
                '';
              };

              userName = mkOption {
                type = types.str;
                default = "restic-${name}";
                description = ''
                  System user receiving pushes from this source. Convention:
                  `restic-<source>`. Must match the corresponding source-side
                  `restic-backup.targets.<...>.sftpUser`.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Named source hosts allowed to push backups to this receiver. One
        chrooted SFTP-only system user is created per source.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users = mapAttrs' (
      name: src:
      nameValuePair src.userName {
        isSystemUser = true;
        group = src.userName;
        home = src.storagePath;
        createHome = false;
        openssh.authorizedKeys.keys = [ src.sshKey ];
        description = "restic receiver for ${name}";
      }
    ) cfg.sources;

    users.groups = mapAttrs' (
      _name: src:
      nameValuePair src.userName { }
    ) cfg.sources;

    systemd.tmpfiles.rules = concatMap (
      name:
      let src = cfg.sources.${name}; in [
        "d ${src.storagePath} 0755 root root -"
        "d ${src.storagePath}/repo 0700 ${src.userName} ${src.userName} -"
      ]
    ) sourceNames;

    services.openssh.extraConfig = mkAfter (
      concatMapStringsSep "\n" (
        name:
        let src = cfg.sources.${name}; in ''
          Match User ${src.userName}
            ChrootDirectory ${src.storagePath}
            ForceCommand internal-sftp
            AllowTcpForwarding no
            X11Forwarding no
            PermitTunnel no
            PasswordAuthentication no
        ''
      ) sourceNames
      + ''


        Match all
      ''
    );
  };
}
