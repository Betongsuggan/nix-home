{ inputs }:
(final: prev: {
  niri-stable = inputs.niri.packages.${prev.stdenv.hostPlatform.system}.niri-stable.overrideAttrs (oldAttrs: {
    doCheck = false;
    # niri v26.04 dropped `/usr/bin/niri` from resources/niri.service in favour of bare `ExecStart=niri`,
    # but niri-flake still applies its v25.x-era `/usr/bin -> $out/bin` substitution to niri-stable.
    # Replace the postFixup with the new-style substitution the unstable channel already uses.
    postFixup = ''
      substituteInPlace $out/lib/systemd/user/niri.service \
        --replace-fail "ExecStart=niri" "ExecStart=$out/bin/niri"
    '';
  });
})
