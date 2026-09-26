# pam_fprintd_grosshack: fprintd's PAM module, patched to ask for the
# password and the fingerprint at the same time (whichever comes first wins),
# instead of fingerprint first and the password only after a timeout.
# Not in nixpkgs; used by modules/fingerprint.
(final: prev: {
  pam-fprint-grosshack = prev.stdenv.mkDerivation {
    pname = "pam-fprint-grosshack";
    version = "0.3.0-unstable-2022-05-26";

    src = prev.fetchFromGitLab {
      owner = "mishakmak";
      repo = "pam-fprint-grosshack";
      rev = "45b42524fb5783e1e555067743d7e0f70d27888a";
      hash = "sha256-obczZbf/oH4xGaVvp3y3ZyDdYhZnxlCWvL0irgEYIi0=";
    };

    # pam_wrapper is only for the test suite (not built here) and isn't in
    # nixpkgs
    postPatch = ''
      substituteInPlace meson.build --replace-fail \
        "dependency('pam_wrapper', required: get_option('pam'))" \
        "dependency('pam_wrapper', required: false)"
    '';

    nativeBuildInputs = with prev; [
      meson
      ninja
      pkg-config
      python3
      glib # gdbus-codegen
    ];

    buildInputs = with prev; [
      glib
      libfprint
      polkit
      dbus
      systemd
      pam
    ];

    mesonFlags = [ "-Dpam_modules_dir=${placeholder "out"}/lib/security" ];

    meta = {
      description = "PAM module accepting a fingerprint or a password at the same prompt";
      homepage = "https://gitlab.com/mishakmak/pam-fprint-grosshack";
      license = prev.lib.licenses.gpl2Plus;
      platforms = prev.lib.platforms.linux;
    };
  };
})
