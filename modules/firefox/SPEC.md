# Firefox

Configures Firefox with privacy-focused settings, hardware video acceleration, pre-installed extensions, and custom search engines. Automatically sets the VA-API driver based on system GPU configuration.

## Usage

```nix
firefox.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Firefox browser for user |

## Notes

- Sets `MOZ_ENABLE_WAYLAND=1` for native Wayland support.
- Automatically selects the correct VA-API driver (`radeonsi` for AMD, `iHD`/`i965` for Intel) based on `osConfig.graphics`.
- Pre-installed extensions: Vimium, uBlock Origin, Bitwarden, Privacy Badger, Decentraleyes, ClearURLs, SponsorBlock.
- Default search engine is DuckDuckGo, with custom engines for Nix Packages (`@np`), NixOS Wiki (`@nw`), and GitHub (`@gh`).
- Privacy settings include: tracking protection, do-not-track header, restricted cross-origin referrers, first-party-only cookies.
- Performance settings include: disk cache disabled (memory-only, 512 MB), WebRender enabled, session store interval set to 30 seconds.
- Enables `toolkit.legacyUserProfileCustomizations.stylesheets` for Stylix theming support.
