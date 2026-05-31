{ lib }:

# Per-host and per-device metadata. Source of truth for cross-host references.
#
# hosts — NixOS machines:
#   hosts.<host>.tailnetName  -- short name registered on the headscale tailnet
#                                (matches networkmanager.hostName on that host)
#   hosts.<host>.addresses    -- LAN/WAN/aliased addresses (optional)
#   hosts.<host>.ssh.host     -- /etc/ssh/ssh_host_ed25519_key.pub
#   hosts.<host>.ssh.users.<user>.<keyname>  -- per-user SSH pubkeys
#
# devices — non-NixOS devices (phones, handhelds):
#   devices.<device>.type          -- "android", etc. (informational)
#   devices.<device>.description   -- human-readable label
#   devices.<device>.syncthing.id  -- Syncthing device ID (public key hash)
#   devices.<device>.tailnetName   -- (optional) headscale tailnet short name
#
# SSH keys are nested under .ssh so `lib.collect lib.isString` on that subtree
# yields a clean list of keys (no addresses or tailnet names mixed in).

let
  hosts = {
    bits = {
      tailnetName = "bits-nixos";
      addresses = [ "bits" ];
      ssh = {
        host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcnHOXC9oIhImCClI4g+TpRtEUTf3l2V7U3JQOtId/i root@bits-nixos";
        users = {
          birgerrydback = {
            bits = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC67mvs+2WPmMHch87LUxKBhJkc71RK5ErZYmB536OeMoiu1zi+p+XkoVrynW8BwZeGP5plbc0opgh10NqAWXGNaKWQOddDJ2e1DwkX1McbexkRqs3Q7ycUbR1VDbiXn9o9Qd8ve/YbT6gG+9eAL92BBPRPkFpeXd9J5Rf6DxJxrMFtx9g6rXK0ehF+Rte+xOwWuT7dcazZwEZ563LJuNvAVoodd8kzPnikTNNw6z9iUfULC+WN5TjuxTsME+HrAuClqvWtSLkzhF1lmzgZbHEyPwL16nhZ/dkPAUbxON0YvFLjF5VTDfzrpk8hjAIWX0CiIw4gwo9M5LJInQlabmM+yecs8dDjjzEGuJAH9l5znoz026nPdxPgS0jp6QNtY4e5Mr8d64B72vDHotBRsyMDnQpIb36KIE52LroHnt7tjgRUo/YDoDmpUB8KuVLSibAoBfGW3CqP5Vv35VXnb/275xirAkjyzWTpUxc6pGkltZ+zv5vFFXno2L0HNTDxy08= birgerrydback@bits-nixos";
            id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrFmjA+/q8wFK4Y/LqAH3y5Zl5uEr8jpgZqV5nTwhkc9qPVQPyTAHyFRdgmhe5IFPu2phuDoAJiHBAGiWfMJrDtDF5/g7Fa7Y6bvx69OmB8Hs+GpCiPXvjl+T8QoHmLuUzW2chIsefRqQc5K3B0YrBqlbA/uB2fkqFHqi8Fnj9Lg809IpaqwngXSWGHZczPF3JMGIIa2sjkHCVk3jvECtURdcj+omFeh9Skm/zqTIYyM160YmFwkpxS8cDfgu2A1WMrVzFmP0jRZ6eidWGduDmsVl6er7Rrx0sI0HrzAV6xOIphRQkeNwkHsrVsPSyYRdByTyjmiRWS7n1KRf4tl5xiJaidqwoQjGBbYW4Nxek9CUhE+UyQv6Za6yS0Tlw4vnanPcyEtusMPfjxEIBZN8Xg6FuXJpkfD4Tbb8ioQ/JLVnbrkYf6pcs//ZbCDR7wD6NX70I6DVMAsSd2IqaLDnkCSqPNpcSxFbzqQxgfE8ZbwgFYU3lLoIdMzpu5kp1sP0= birgerrydback@nixos";
          };
        };
      };
    };

    controller = {
      tailnetName = "controller";
      addresses = [
        "192.168.50.5"
        "rydback.net"
        "controller"
      ];
      ssh = {
        host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGf64nW+ZcG2TfzvS4Ql2yJD2/gNpNsRcUQrK0jNKb9 root@controller";
        users = {
          betongsuggan = {
            ssh_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAR/t68PUZdYs0cECO0yPuywEBvFJQAGVMp4t6IkZIRz rydback@gmail.com";
          };
        };
      };
    };

    island = {
      tailnetName = "island";
      addresses = [ "island" ];
      ssh = {
        users = {
          betongsuggan = {
            id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCOlpUl/qIipCBKP3Opoo+FxrsfX0zoh/5LrkVso1qlH2AWj3IDEHnoWpibqxtDYhU5J7CTJzvhh6AuIZLTb2plB/bu6hrh7y2/Sm3nkvOt1qZgXU4PERVjEOCu4hZQpHXpPtnNL0xYwr/bQ8eaz6f5oio2jn8xNo5YVv8jLjZSNHbPX/rcfuQz9xsAGNafOfpmM0+0ZjFlgpj/J791VhuM7w4XrJ6zzUYYqXvpo3mA49vpr/R2v1hktQmo0gCoIwQISLH8henuGCgaL51eCjze6mMygb37SjI/3nORoYNy2mxt25Twktpj20oc95HUB9aiUEn/pOoJVCaEVLugvu1IBbpwgfeP2Ymy6N2MyZ5daGlhUujOYg0LGHXFyvIC5db9P04MoaUPZMg9/4E+PagHKy11bKheWvNNkizFjo2FXil4tYf/0/wxWiSXzlPpRdROgGItTXrTtFcuDfooEtbjignxtB4EdIo32KC2VZ2a217PLdfbDhabSu2/Ogh503ZnKDQl8TV1kpFoyg7QkE3TBblrGWozrHUD66UypS8fU5UcpULXQyhKkZusgZ41td+97sbsQESqnSy8jOl+yFSg0gdiaLSfUaCOX+ybDNdSJJsFhPDJsQfV8f5/ZpyCFw9nwt2wZ8kf5eB2RQ6x8bg8tfOQZ3o32RaqzD5pJLTzw== rydback@gmail.com";
          };
        };
      };
    };

    desktop = {
      tailnetName = "desktop";
      addresses = [ "desktop" ];
      ssh = {
        host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPgyXzp0dQ+uwIHBV6RGsNASeKgMMQb9NFX5Dv/xPrvE root@home-desktop";
        users = {
          betongsuggan = {
            id_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvvJ1JmeY0gc1NgbsTgELa7on4xjtW3ZJfJ5MRMgrmQhg+yMWJyMpS6M0Z9b1aLRp1Fnvq7TDX40PiFlQZ+0rRHOty8JbwPoTchTSyg3ihxvtUP6slZsgJlsZuvEwDFZ42nB/U4oWD2i2o7smzB6T5fBIYmNgM2bzWLqAS+xHo+k8SsxOaimDmmxSuA+qhHkK9fdgfuu0phZAKfo/5dBXcHNyRWsT6o81KNUXhlNYMSagt9IZEx204dt7m9SKZG6SzHslrEPqf+RETP4sQyh+u5YfgpVgww8AHvJcveKsNkegjbwVSyekbANwJlU54lxnKR9Td6G7kYFf/z+QQt3whGKJJ89KvvqxPccCQfd/Es8IYSXJEMu1OFEL7yOFggSicnoYCUq6ZZAzTnabjB7uRflfTAjmJrT78jbWMIiyY/U30zgJ8ak6Ijho9i+3dqDk2zOWwatJ7CfV6/izDzcPI4tqne7L0MKy2Z7vExJ9rWCdP58dBR0LewuCQAb9E5MVTKcPRxmRjcrKuzkgrvGxtbDG4tbxsQ1KNtRmYAlTiiIFDVVmM1vckuAqV/aaPFaGN9qUppUajl/Dz0BLqEK0WJcQ3ZX6ChQeNOXZQrOQaofMwcQlGu+YSz+Xvus1a3Ygb1zoJvUukxYUU3KSomtx6Vvs1f3+sm4kJgFXOgL5Qmw== betongsuggan@home-desktop";
          };
        };
      };
    };
  };

  devices = {
    ayn-thor = {
      type = "android";
      description = "Ayn Odin 2 Thor -- Android gaming handheld";
      syncthing.id = "2VW22JQ-ARR4C4E-6DMSO7O-TW64TDQ-DYBJNXX-7HICKTH-EMEI2R5-QTAUTAH";
    };
    fairphone = {
      type = "android";
      description = "Fairphone -- daily driver";
      syncthing.id = "REPLACE-WITH-REAL-DEVICE-ID";
    };
  };
in
{
  inherit hosts devices;

  tailnet = {
    baseDomain = "ts.rydback.net";
    fqdn = host: "${hosts.${host}.tailnetName}.ts.rydback.net";
  };

  allSshKeys = lib.concatLists (
    map (h: lib.collect lib.isString (h.ssh or { })) (lib.attrValues hosts)
  );

  # Every { host, user } pair in `hosts` that has at least one SSH key under
  # `ssh.users.<user>`. Lets a host authorize "everyone in lib who's <user>"
  # without enumerating peers by hand.
  allPeersFor =
    user:
    lib.mapAttrsToList (host: _: { inherit host user; }) (
      lib.filterAttrs (_: h: (h.ssh.users.${user} or null) != null) hosts
    );

  # Every { host, user } combination defined under `ssh.users.*` across the
  # whole fleet — i.e. "every user-pubkey we know about, by origin". Used by
  # controller to grant all those keys SSH access as its local admin user,
  # so adding a new host to lib automatically grants login after rebuild.
  allUserPeers = lib.concatLists (
    lib.mapAttrsToList (
      host: h: map (user: { inherit host user; }) (lib.attrNames (h.ssh.users or { }))
    ) hosts
  );

  allSyncthingDevices = lib.filterAttrs (
    _: d: d ? syncthing && d.syncthing ? id
  ) (lib.mapAttrs (_: d: { id = d.syncthing.id; }) devices);
}
