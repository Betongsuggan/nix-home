# File Sharing

Configures network file sharing via Samba (SMB). Supports defining multiple shares with per-share access control, and enables WSDD for network discovery by Windows and Android clients.

## Usage

```nix
file-sharing = {
  enable = true;
  samba = {
    enable = true;
    openFirewall = true;
    shares = [
      {
        name = "shared";
        path = "/home/user/shared";
        validUsers = [ "user" ];
        readOnly = false;
      }
    ];
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable file sharing |
| samba.enable | bool | false | Enable Samba (SMB) file sharing |
| samba.shares | list of share | [] | List of Samba share definitions |
| samba.workgroup | string | "WORKGROUP" | Network workgroup name |
| samba.allowedSubnets | list of string | ["192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12"] | Subnets allowed to access Samba shares |
| samba.openFirewall | bool | false | Automatically open firewall ports for Samba |

Each share in `samba.shares` has the following attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| name | string | (required) | Name of the share (visible on network) |
| path | path | (required) | Path to the shared directory |
| validUsers | list of string | [] | List of users allowed to access this share |
| readOnly | bool | false | Whether the share is read-only |

## Notes

- SMB1 is disabled; only SMB2.10 and above are permitted.
- Samba user passwords must be set separately using `smbpasswd -a <username>`.
- WSDD (Web Services Dynamic Discovery) is automatically enabled alongside Samba for network visibility.
