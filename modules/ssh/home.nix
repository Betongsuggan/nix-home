# SSH client config derived from the lib registry: a Host block for every
# fleet account this user may log into (the targets' sshFrom), the public
# halves of this user's keys, and an ssh-agent.
{
  config,
  lib,
  inputs,
  osConfig,
  ...
}:
with lib;

let
  cfg = config.my.ssh;
  selfLib = inputs.self.lib;
  host = osConfig.my.common.host;
  user = config.home.username;
  keys = selfLib.hosts.${host}.users.${user}.ssh or { };
  keyFile = name: "${config.home.homeDirectory}/.ssh/${name}";
  identities = map keyFile (selfLib.sshIdentities host user);
in
{
  options.my.ssh.enable = mkEnableOption "fleet SSH client config and ssh-agent";

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      # The legacy implicit defaults ("*" block) match OpenSSH's own defaults
      enableDefaultConfig = false;
      settings = listToAttrs (
        map (
          target:
          let
            fqdn = selfLib.tailnet.fqdn target.host;
          in
          nameValuePair "${target.host} ${fqdn}" {
            HostName = fqdn;
            User = target.user;
            IdentityFile = if length identities == 1 then head identities else identities;
            IdentitiesOnly = true;
          }
        ) (selfLib.sshTargetsOf host user)
      );
    };

    home.file = mapAttrs' (name: pub: nameValuePair ".ssh/${name}.pub" { text = pub + "\n"; }) keys;

    services.ssh-agent.enable = true;
    systemd.user.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };
}
