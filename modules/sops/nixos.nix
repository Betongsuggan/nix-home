{
  config,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.sops;
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

    # PC/SC daemon for smartcard access — needed when editing sops secrets on
    # this host via age-plugin-yubikey. Cheap to leave on for non-editing hosts.
    services.pcscd.enable = true;
  };
}
