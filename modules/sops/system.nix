{ config, lib, ... }:

with lib;

let cfg = config.sops-secrets;
in {
  options.sops-secrets = {
    enable = mkEnableOption "sops-nix-managed secrets for this host";

    secretsFile = mkOption {
      type = types.path;
      description = ''
        Path to the encrypted YAML file for this host. Typically a path into
        the nix-secrets flake input, e.g. `"\${inputs.nix-secrets}/secrets/<host>.yaml"`.
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
    openssh.enable = true;

    # PC/SC daemon for smartcard access — needed when editing sops secrets on
    # this host via age-plugin-yubikey. Cheap to leave on for non-editing hosts.
    services.pcscd.enable = true;
  };
}
