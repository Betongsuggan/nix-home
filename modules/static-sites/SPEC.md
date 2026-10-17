# Static Sites

Serve a directory from the Nix store under a URL prefix of an existing reverse-proxy domain. No daemon, no directory on disk: the site is a package, nginx gets a `root` pointing into the store, and a new version is a rebuild.

## Usage

```nix
my.reverse-proxy.domains = [ "example.com" ];   # the vhost (cert, 404 stub) comes from reverse-proxy

my.static-sites.sites.wow = {
  package = pkgs.wow-guide;                      # output = site root, index.html at the top
  # domain = lib.domain;                         # default: the fleet domain
  # path = "/wow";                               # default: "/<name>"
};
```

Result: `https://example.com/wow/` serves `${pkgs.wow-guide}/index.html`, `https://example.com/wow` redirects to `/wow/`, and every file under the package is reachable by its relative path.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| sites | attrset | { } | Sites keyed by short name |
| sites.\<name\>.domain | string | `lib.domain` | Vhost FQDN; must be in `my.reverse-proxy.domains` (asserted) |
| sites.\<name\>.path | string | `"/<name>"` | One-segment URL prefix, no trailing slash |
| sites.\<name\>.package | package | (required) | Derivation whose output is the site root |
| sites.\<name\>.cacheControl | string | `"public, max-age=300"` | Cache-Control header on every file |
| sites.\<name\>.extraConfig | lines | "" | Extra nginx config in the site's location block |

## Notes

- Sites are **public** unless `extraConfig` restricts them (for tailnet-only, pass `inputs.self.lib.tailnet.nginxAllowOnly [ ]` and add the domain to headscale's `extraDnsRecords` like the other tailnet-only names).
- The location uses nginx `root` on a `linkFarm` (`<store>/<prefix> -> <package>`), never `alias`: gixy flags `alias` under a prefix location, and `root` needs no path arithmetic.
- The site must use relative links (or links that start with its prefix): it is served under `/<prefix>/`, not at `/`.
- Only `GET` and `HEAD` are allowed; everything else is denied in the location.
- Updating a site = updating its package (for a flake-input site: `nix flake update <input>`, commit `flake.lock`, rebuild).
