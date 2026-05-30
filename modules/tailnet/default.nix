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
        pubkeys under `lib.hosts.<host>.ssh.users.<user>.*` are added to that
        local user's `authorized_keys`.
      '';
    };
  };

  config = mkIf cfg.enable {
    tailscale-client = {
      enable = true;
      loginServer = "https://vpn.rydback.net";
      authKeyFile = config.sops.secrets."headscale-preauthkey".path;
      extraUpFlags = [ "--accept-routes" "--accept-dns" ];
    };

    sops.secrets."headscale-preauthkey" = {
      key = "services/headscale-preauthkey";
      owner = "root";
      mode = "0400";
    };

    openssh = {
      enable = true;
      openFirewall = false;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

    # nix-daemon (root) reaches nix-vault over the tailnet using the host SSH
    # key. Scoped to root so the user's own SSH config is unaffected.
    programs.ssh.extraConfig = ''
      Match user root host ${selfLib.tailnet.fqdn "controller"}
        IdentityFile /etc/ssh/ssh_host_ed25519_key
        IdentitiesOnly yes
    '';

    users.users = mapAttrs (_localUser: peers: {
      openssh.authorizedKeys.keys = concatMap
        (p: collect isString (selfLib.hosts.${p.host}.ssh.users.${p.user} or { }))
        peers;
    }) cfg.authorizeSshFor;
  };
}
