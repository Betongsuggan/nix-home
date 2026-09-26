{ lib }:

let
  domain = "rydback.net";
  baseDomain = "ts.${domain}";

  # The person operating the fleet
  operator = {
    email = "rydback@gmail.com";
    yubikey = {
      # FIDO resident SSH key (touch-only): the bootstrap credential used to
      # reach controller before a new host has keys of its own
      ssh = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAII8ur6g8BqxDaC2/PQngQa/eEBHT7RrDtukpiacTByKaAAAADXNzaDpuaXgtdmF1bHQ= yubikey-bootstrap";
      # age recipient of the same YubiKey, the admin recipient in nix-vault
      ageRecipient = "age1yubikey1qtzynkrvd7yxa8zvnx2jd036uvklyvzmsfmq8zhpqppr3g6phfvlwc6lyd3";
    };
  };

  # One entry per directory under hosts/; flake.nix builds a
  # nixosConfiguration for each (lib/mk-host.nix). Optional fields default to:
  #   system = "x86_64-linux";
  #   hostName = <attribute name>;  (also the host's tailnet name)
  hostEntries = {
    bits = {
      hostName = "bits-nixos";
      addresses = [ "bits" ];
      ssh.host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcnHOXC9oIhImCClI4g+TpRtEUTf3l2V7U3JQOtId/i root@bits-nixos";
      users.birgerrydback = {
        # Fleet logins use the `bits` key; `id_rsa` is the GitHub identity
        sshIdentities = [ "bits" ];
        sshFrom = [
          {
            host = "controller";
            user = "betongsuggan";
          }
        ];
        syncthing.id = "O6CQT6T-QUDEZ3C-LPG6NY5-E6VLNWN-SBAQISQ-GPE4HXK-PHJQL33-RMOQZQ6";
        ssh = {
          bits = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC67mvs+2WPmMHch87LUxKBhJkc71RK5ErZYmB536OeMoiu1zi+p+XkoVrynW8BwZeGP5plbc0opgh10NqAWXGNaKWQOddDJ2e1DwkX1McbexkRqs3Q7ycUbR1VDbiXn9o9Qd8ve/YbT6gG+9eAL92BBPRPkFpeXd9J5Rf6DxJxrMFtx9g6rXK0ehF+Rte+xOwWuT7dcazZwEZ563LJuNvAVoodd8kzPnikTNNw6z9iUfULC+WN5TjuxTsME+HrAuClqvWtSLkzhF1lmzgZbHEyPwL16nhZ/dkPAUbxON0YvFLjF5VTDfzrpk8hjAIWX0CiIw4gwo9M5LJInQlabmM+yecs8dDjjzEGuJAH9l5znoz026nPdxPgS0jp6QNtY4e5Mr8d64B72vDHotBRsyMDnQpIb36KIE52LroHnt7tjgRUo/YDoDmpUB8KuVLSibAoBfGW3CqP5Vv35VXnb/275xirAkjyzWTpUxc6pGkltZ+zv5vFFXno2L0HNTDxy08= birgerrydback@bits-nixos";
          id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrFmjA+/q8wFK4Y/LqAH3y5Zl5uEr8jpgZqV5nTwhkc9qPVQPyTAHyFRdgmhe5IFPu2phuDoAJiHBAGiWfMJrDtDF5/g7Fa7Y6bvx69OmB8Hs+GpCiPXvjl+T8QoHmLuUzW2chIsefRqQc5K3B0YrBqlbA/uB2fkqFHqi8Fnj9Lg809IpaqwngXSWGHZczPF3JMGIIa2sjkHCVk3jvECtURdcj+omFeh9Skm/zqTIYyM160YmFwkpxS8cDfgu2A1WMrVzFmP0jRZ6eidWGduDmsVl6er7Rrx0sI0HrzAV6xOIphRQkeNwkHsrVsPSyYRdByTyjmiRWS7n1KRf4tl5xiJaidqwoQjGBbYW4Nxek9CUhE+UyQv6Za6yS0Tlw4vnanPcyEtusMPfjxEIBZN8Xg6FuXJpkfD4Tbb8ioQ/JLVnbrkYf6pcs//ZbCDR7wD6NX70I6DVMAsSd2IqaLDnkCSqPNpcSxFbzqQxgfE8ZbwgFYU3lLoIdMzpu5kp1sP0= birgerrydback@nixos";
        };
      };
    };

    controller = {
      tailnetIp = "100.64.0.2";
      lan = {
        subnet = "192.168.50.0/24";
        gateway = "192.168.50.1";
      };
      addresses = [
        "192.168.50.5"
        "rydback.net"
        "controller"
      ];
      ssh.host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGf64nW+ZcG2TfzvS4Ql2yJD2/gNpNsRcUQrK0jNKb9 root@controller";
      users = {
        betongsuggan = {
          syncthing.id = "4AUKVSW-5SDSOZS-WLDB5LE-YJAVG3C-YMABN52-HEQTHJP-PCBEVCC-EEWM6AH";
          # Every fleet identity may log in here (admin hub)
          sshFromFleet = true;
          ssh.id_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAR/t68PUZdYs0cECO0yPuywEBvFJQAGVMp4t6IkZIRz rydback@gmail.com";
        };
        restic = {
          ssh.id_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpk7NPFSW1LjC9gB89bQuS3QwpoKYotzb3RJGd3cvgE restic@controller";
        };
      };
    };

    island-stationary = {
      addresses = [ "island-stationary" ];
      # FIXME: placeholder — real MAC from `ip -br link` on island-stationary
      # (the wired NIC). Woken from island-pi: `ssh island-pi wake-island-stationary`
      wol = {
        mac = "00:00:00:00:00:00";
        relay = "island-pi";
      };
      ssh.host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFadvK7ZRpD4sA+aHutNTz9c6AP8KWWjcSfbKRDmI+Ow root@island-stationary";
      users.betongsuggan = {
        # The FIDO resident key works before /run/secrets exists (onboarding)
        sshIdentities = [
          "id_rsa"
          "id_ed25519_sk_rk_nix-vault"
        ];
        sshFrom = [
          {
            host = "controller";
            user = "betongsuggan";
          }
        ];
        ssh.id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCOlpUl/qIipCBKP3Opoo+FxrsfX0zoh/5LrkVso1qlH2AWj3IDEHnoWpibqxtDYhU5J7CTJzvhh6AuIZLTb2plB/bu6hrh7y2/Sm3nkvOt1qZgXU4PERVjEOCu4hZQpHXpPtnNL0xYwr/bQ8eaz6f5oio2jn8xNo5YVv8jLjZSNHbPX/rcfuQz9xsAGNafOfpmM0+0ZjFlgpj/J791VhuM7w4XrJ6zzUYYqXvpo3mA49vpr/R2v1hktQmo0gCoIwQISLH8henuGCgaL51eCjze6mMygb37SjI/3nORoYNy2mxt25Twktpj20oc95HUB9aiUEn/pOoJVCaEVLugvu1IBbpwgfeP2Ymy6N2MyZ5daGlhUujOYg0LGHXFyvIC5db9P04MoaUPZMg9/4E+PagHKy11bKheWvNNkizFjo2FXil4tYf/0/wxWiSXzlPpRdROgGItTXrTtFcuDfooEtbjignxtB4EdIo32KC2VZ2a217PLdfbDhabSu2/Ogh503ZnKDQl8TV1kpFoyg7QkE3TBblrGWozrHUD66UypS8fU5UcpULXQyhKkZusgZ41td+97sbsQESqnSy8jOl+yFSg0gdiaLSfUaCOX+ybDNdSJJsFhPDJsQfV8f5/ZpyCFw9nwt2wZ8kf5eB2RQ6x8bg8tfOQZ3o32RaqzD5pJLTzw== rydback@gmail.com";
      };
    };

    island-pi = {
      system = "aarch64-linux";
      users.betongsuggan = { };
      addresses = [ "island-pi" ];
      # FIXME: fill in after first boot (onboarding step 2 in
      # hosts/island-pi/SPEC.md): /etc/ssh/ssh_host_ed25519_key.pub. Feeds
      # lib.allSshKeys -> controller's git-server authorized keys, per fleet
      # convention. Left out until known so no bogus key lands on controller.
      # ssh.host = "ssh-ed25519 AAAA... root@island-pi";
    };

    desktop = {
      tailnetIp = "100.64.0.5";
      addresses = [ "desktop" ];
      # USB-Ethernet adapter; reaches the host through the current KVM setup.
      # Woken from controller: `ssh controller wake-desktop` (also by
      # controller's wake-proxy for the AI services)
      wol = {
        mac = "34:1b:22:84:72:67";
        relay = "controller";
      };
      ssh.host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPgyXzp0dQ+uwIHBV6RGsNASeKgMMQb9NFX5Dv/xPrvE root@desktop";
      users.betongsuggan = {
        sshFrom = [
          {
            host = "controller";
            user = "betongsuggan";
          }
          {
            host = "bits";
            user = "birgerrydback";
          }
        ];
        ssh.id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvvJ1JmeY0gc1NgbsTgELa7on4xjtW3ZJfJ5MRMgrmQhg+yMWJyMpS6M0Z9b1aLRp1Fnvq7TDX40PiFlQZ+0rRHOty8JbwPoTchTSyg3ihxvtUP6slZsgJlsZuvEwDFZ42nB/U4oWD2i2o7smzB6T5fBIYmNgM2bzWLqAS+xHo+k8SsxOaimDmmxSuA+qhHkK9fdgfuu0phZAKfo/5dBXcHNyRWsT6o81KNUXhlNYMSagt9IZEx204dt7m9SKZG6SzHslrEPqf+RETP4sQyh+u5YfgpVgww8AHvJcveKsNkegjbwVSyekbANwJlU54lxnKR9Td6G7kYFf/z+QQt3whGKJJ89KvvqxPccCQfd/Es8IYSXJEMu1OFEL7yOFggSicnoYCUq6ZZAzTnabjB7uRflfTAjmJrT78jbWMIiyY/U30zgJ8ak6Ijho9i+3dqDk2zOWwatJ7CfV6/izDzcPI4tqne7L0MKy2Z7vExJ9rWCdP58dBR0LewuCQAb9E5MVTKcPRxmRjcrKuzkgrvGxtbDG4tbxsQ1KNtRmYAlTiiIFDVVmM1vckuAqV/aaPFaGN9qUppUajl/Dz0BLqEK0WJcQ3ZX6ChQeNOXZQrOQaofMwcQlGu+YSz+Xvus1a3Ygb1zoJvUukxYUU3KSomtx6Vvs1f3+sm4kJgFXOgL5Qmw== betongsuggan@desktop";
        syncthing.id = "EWXRMC7-KQBWYJQ-ARRMUO5-WIB3ABU-62ZI35X-RPYASGJ-WYPGZTI-OZLN5AD";
      };
      # The gamer session runs its own Syncthing (emulation-client save sync);
      # controller picks this up via allSyncthingDevices as "desktop-gamer".
      users.gamer = {
        syncthing.id = "RCIVKBJ-RJW3JSL-YHAJQP3-UAF3O32-VMNCGVC-DUI5KTB-X3JFY6M-ML2BAQV";
      };
    };

    # Not on the tailnet (yet): no keys or Syncthing IDs.
    private-laptop = { };
    mail.users.betongsuggan = { };
  };

  # People's login accounts, independent of host. A host gets an account when
  # its registry entry lists the user under `users` or it has a
  # hosts/<host>/user-<name>.nix Home Manager file.
  accounts = {
    betongsuggan = {
      description = "Birger Rydback";
      admin = true;
      git = {
        name = "Betongsuggan";
        email = "rydback@gmail.com";
      };
    };
    birgerrydback = {
      description = "Birger Rydback";
      admin = true;
      git = {
        name = "BirgerRydback";
        email = "birger.rydback@bits.bi";
      };
    };
    gamer = {
      description = "Gaming User";
      admin = false;
      git = accounts.betongsuggan.git;
    };
  };

  hosts = lib.mapAttrs (
    name: h:
    {
      system = "x86_64-linux";
      hostName = name;
    }
    // h
  ) hostEntries;

  devices = {
    ayn-thor = {
      type = "android";
      description = "Ayn Odin 2 Thor -- Android gaming handheld";
      tailnetName = "ayn-thor";
      syncthing.id = "2VW22JQ-ARR4C4E-6DMSO7O-TW64TDQ-DYBJNXX-7HICKTH-EMEI2R5-QTAUTAH";
    };
    fairphone = {
      type = "android";
      description = "Fairphone -- daily driver";
      syncthing.id = "NR2V5JP-3M7XOZ7-KRDE5KF-FHI7AT7-P4NJBYH-VAEDY63-5QEDLN5-UA7SIQ4";
      tailnetName = "fairphone";
    };
  };
in
rec {
  inherit
    accounts
    devices
    domain
    hosts
    operator
    ;

  # For the NixOS half of a module whose switch lives in Home Manager: true
  # if `pred` holds for any Home Manager user's config on this host. Hosts
  # without Home Manager (no user-*.nix) have no users, so it is false there.
  anyHomeUser = config: pred: lib.any pred (lib.attrValues (config.home-manager.users or { }));

  tailnet = {
    inherit baseDomain;
    # headscale, served by controller
    controlDomain = "vpn.${domain}";
    loginServer = "https://vpn.${domain}";
    # Headscale's default address prefixes
    sources = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
    ];
    # nginx `allow` rules for the tailnet (plus `extra` sources), then deny
    nginxAllowOnly =
      extra: lib.concatMapStrings (s: "allow ${s};\n") (extra ++ tailnet.sources) + "deny all;\n";
    fqdn = host: "${hosts.${host}.hostName}.${baseDomain}";
  };

  allSshKeys =
    let
      hostSshKeys = h: lib.collect lib.isString (h.ssh or { });
      userSshKeys =
        h:
        lib.concatLists (
          lib.mapAttrsToList (_: u: lib.collect lib.isString (u.ssh or { })) (h.users or { })
        );
    in
    lib.concatLists (map (h: hostSshKeys h ++ userSshKeys h) (lib.attrValues hosts));

  allPeersFor =
    user:
    lib.mapAttrsToList (host: _: { inherit host user; }) (
      lib.filterAttrs (_: h: (h.users.${user}.ssh or null) != null) hosts
    );

  allUserPeers = lib.concatLists (
    lib.mapAttrsToList (
      host: h:
      map (user: { inherit host user; }) (
        lib.attrNames (lib.filterAttrs (_: u: u ? ssh) (h.users or { }))
      )
    ) hosts
  );

  # Fleet identities allowed to SSH into `user` on `host`, from the
  # registry's sshFrom / sshFromFleet.
  sshFrom =
    host: user:
    let
      u = hosts.${host}.users.${user} or { };
    in
    if u.sshFromFleet or false then allUserPeers else u.sshFrom or [ ];

  # The reverse view: every { host, user } that `user`@`host` may SSH into.
  sshTargetsOf =
    host: user:
    lib.concatLists (
      lib.mapAttrsToList (
        targetHost: h:
        lib.concatMap (
          targetUser:
          lib.optional (targetHost != host && lib.elem { inherit host user; } (sshFrom targetHost targetUser))
            {
              host = targetHost;
              user = targetUser;
            }
        ) (lib.attrNames (h.users or { }))
      ) hosts
    );

  # Key files (under ~/.ssh) that `user`@`host` authenticates to the fleet with
  sshIdentities =
    host: user:
    let
      u = hosts.${host}.users.${user} or { };
    in
    u.sshIdentities or (lib.attrNames (u.ssh or { }));

  allSyncthingDevices =
    let
      collectIds =
        src:
        lib.mapAttrs (_: x: {
          id = x.syncthing.id;
          tailnetFqdn =
            if x ? tailnetName then
              "${x.tailnetName}.${baseDomain}"
            else if x ? hostName then
              "${x.hostName}.${baseDomain}"
            else
              null;
        }) (lib.filterAttrs (_: x: x ? syncthing && x.syncthing ? id) src);
      hostUserIds = lib.listToAttrs (
        lib.concatMap (
          hostName:
          let
            h = hosts.${hostName};
          in
          lib.mapAttrsToList (
            userName: u:
            lib.nameValuePair "${hostName}-${userName}" {
              id = u.syncthing.id;
              tailnetFqdn = "${h.hostName}.${baseDomain}";
            }
          ) (lib.filterAttrs (_: u: u ? syncthing && u.syncthing ? id) (h.users or { }))
        ) (lib.attrNames hosts)
      );
    in
    collectIds devices // collectIds hosts // hostUserIds;
}
