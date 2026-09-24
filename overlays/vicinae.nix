inputs: final: prev:
let
  vicinae = inputs.vicinae.packages.${prev.stdenv.hostPlatform.system};
  extension =
    pname: dir:
    vicinae.mkVicinaeExtension {
      inherit pname;
      src = "${inputs.vicinae-extensions}/extensions/${dir}";
    };
in
{
  # nixpkgs 26.05 ships a newer LayerShellQt whose <LayerShellQt/Shell>
  # header no longer transitively declares LayerShellQt::Window.
  # native-file-chooser.cpp uses Shell::Window (= LayerShellQt::Window)
  # but only includes <LayerShellQt/Shell>, so it fails to compile.
  # Add the missing include until the fix lands in vicinae-fork.
  vicinae = vicinae.default.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      cpp="$(find . -path '*services/file-chooser/native/native-file-chooser.cpp' | head -1)"
      if [ -n "$cpp" ]; then
        sed -i '/#include <LayerShellQt\/Shell>/a #include <LayerShellQt/Window>' "$cpp"
      fi
    '';
  });

  vicinae-wifi-commander = extension "wifi-commander" "wifi-commander";
  vicinae-bluetooth = extension "bluetooth" "bluetooth";
  vicinae-monitor = extension "hyprland-monitors" "hyprland-monitors";
}
