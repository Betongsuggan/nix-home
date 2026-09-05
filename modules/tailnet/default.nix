{ config, lib, inputs, ... }:

with lib;

let
  cfg = config.tailnet;
  selfLib = inputs.self.lib;
in
{
  options.tailnet = {
    enable = mkEnableOption "Tailnet membership with bundled SSH server + client defaults";

    authorizeSshFor = mkOption {
      type = types.attrsOf (types.listOf (types.submodule {
        options = {
          host = mkOption {
            type = types.str;
            description = "Tailnet host name (must be a key in flake.lib.hosts).";
          };
          user = mkOption {
            type = types.str;
            description = "Username on the peer host whose SSH keys to authorize.";
          };
        };
      }));
      default = { };
      example = {
        betongsuggan = [
          { host = "bits"; user = "birgerrydback"; }
          { host = "controller"; user = "betongsuggan"; }
        ];
      };
      description = ''
        Map of local user → list of `{host, user}` peer identities. All SSH
        pubkeys under `lib.hosts.<host>.users.<user>.ssh.*` are added to that
        local user's `authorized_keys`.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      tailscale-client = {
        enable = true;
        loginServer = "https://vpn.rydback.net";
        extraUpFlags = [ "--accept-routes" "--accept-dns" ];
      };

      openssh = {
        enable = true;
        openFirewall = false;
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

      # nix-daemon (root) reaches nix-vault over the tailnet using the host SSH
      # key. `localuser` (not `user`) is the criterion for the local account
      # running ssh — `Match user` matches the *remote* login name, and these
      # fetches log in as git@controller, so a `Match user root` block never
      # applies and root falls back to nonexistent /root/.ssh keys. Scoped to
      # localuser root + remote user git so neither user SSH configs nor root's
      # admin logins to controller are affected.
      programs.ssh.extraConfig = ''
        Match localuser root user git host ${selfLib.tailnet.fqdn "controller"}
          IdentityFile /etc/ssh/ssh_host_ed25519_key
          IdentitiesOnly yes
      '';

      users.users = mapAttrs (_localUser: peers: {
        openssh.authorizedKeys.keys = concatMap
          (p: collect isString (selfLib.hosts.${p.host}.users.${p.user}.ssh or { }))
          peers;
      }) cfg.authorizeSshFor;
    }

    (mkIf config.sops-secrets.enable {
      tailscale-client.authKeyFile = config.sops.secrets."headscale-preauthkey".path;

      sops.secrets."headscale-preauthkey" = {
        key = "services/headscale-preauthkey";
        owner = "root";
        mode = "0400";
      };
    })
  ]);
}
