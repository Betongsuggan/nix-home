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
    my.openssh.enable = true;

    # PC/SC daemon for smartcard access — needed when editing sops secrets on
    # this host via age-plugin-yubikey. Cheap to leave on for non-editing hosts.
    services.pcscd.enable = true;
  };
}
