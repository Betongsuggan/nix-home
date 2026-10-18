{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.sops;

  # Users who edit nix-vault on this host (Home Manager `my.sops.enable`)
  editors = attrNames (filterAttrs (_: u: u.my.sops.enable or false) (config.home-manager.users or { }));
  hostKey = "/etc/ssh/ssh_host_ed25519_key";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.my.sops = {
    enable = mkEnableOption "sops-nix-managed secrets for this host";

    secretsFile = mkOption {
      type = types.path;
      description = ''
        Path to the encrypted YAML file for this host. Typically a path into
        the nix-vault flake input, e.g. `"\${inputs.nix-vault}/secrets/<host>.yaml"`.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = cfg.secretsFile;
      defaultSopsFormat = "yaml";
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    # sops-nix decrypts using the host's SSH host key; the openssh module is
    # the canonical place to ensure that key exists.
    services.openssh.enable = true;

    # Every registry SSH key of this host's accounts, decrypted to
    # ~/.ssh/<key> from users/<user>/ssh/<key> in the host's secrets file
    sops.secrets = listToAttrs (
      concatMap (
        user:
        map (
          key:
          nameValuePair "ssh-${user}-${key}" {
            key = mkDefault "users/${user}/ssh/${key}";
            owner = user;
            mode = "0600";
            path = "${config.users.users.${user}.home}/.ssh/${key}";
          }
        ) (attrNames (inputs.self.lib.hosts.${config.my.common.host}.users.${user}.ssh or { }))
      ) config.my.common.accounts
    );

    # sops identities for each vault editor: this host's age key (from the SSH
    # host key, so `sops` opens this host's own secrets file without the
    # YubiKey) followed by the YubiKey stub (every file). Generated as root
    # because only root can read the host key; regenerated on every switch.
    # Skipped until sshd has created the host key.
    system.activationScripts.sops-editor-keys = mkIf (editors != [ ]) {
      deps = [ "users" ];
      text = concatMapStrings (
        user:
        let
          u = config.users.users.${user};
          dir = "${u.home}/.config/sops/age";
        in
        ''
          if [ -e ${hostKey} ]; then
            for d in ${u.home}/.config ${u.home}/.config/sops ${dir}; do
              [ -d "$d" ] || install -d -m 700 -o ${user} -g ${u.group} "$d"
            done
            tmp=$(mktemp ${dir}/.keys.txt.XXXXXX)
            printf '%s\n' "$(${getExe pkgs.ssh-to-age} -private-key -i ${hostKey})" \
              ${escapeShellArg inputs.self.lib.operator.yubikey.ageIdentity} > "$tmp"
            chown ${user}:${u.group} "$tmp"
            chmod 600 "$tmp"
            mv -f "$tmp" ${dir}/keys.txt
          fi
        ''
      ) editors;
    };

    # PC/SC daemon for smartcard access — needed when editing sops secrets on
    # this host via age-plugin-yubikey. Cheap to leave on for non-editing hosts.
    services.pcscd.enable = true;
  };
}
