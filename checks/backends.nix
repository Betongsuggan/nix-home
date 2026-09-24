# Evaluation checks for the alternatives no host uses today: every backend
# of every multi-backend module, and the optional desktop modules. Each check
# is one Home Manager user (private-laptop's, with overrides) and succeeds
# when its activation package evaluates, so an unused backend can no longer
# silently rot. Run with `nix flake check --no-build`.
{ self, lib }:
let
  base = self.nixosConfigurations.private-laptop;
  user = "betongsuggan";

  variant =
    settings:
    (base.extendModules {
      modules = [ { home-manager.users.${user} = lib.mkMerge [ settings ]; } ];
    }).config.home-manager.users.${user}.home.activationPackage;

  backendsOf =
    option: values: lib.genAttrs values (v: variant (lib.setAttrByPath option (lib.mkForce v)));
  prefixed = prefix: lib.mapAttrs' (n: v: lib.nameValuePair "${prefix}-${n}" v);
in
prefixed "wm" (
  backendsOf
    [
      "my"
      "window-manager"
      "backend"
    ]
    [
      "hyprland"
      "niri"
      "sway"
      "i3"
    ]
)
// prefixed "launcher" (
  backendsOf
    [
      "my"
      "launcher"
      "backend"
    ]
    [
      "vicinae"
      "walker"
      "rofi"
      "wofi"
    ]
)
// prefixed "terminal" (
  backendsOf
    [
      "my"
      "terminal"
      "backend"
    ]
    [
      "alacritty"
      "ghostty"
      "urxvt"
    ]
)
// prefixed "shell" (
  backendsOf
    [
      "my"
      "shell"
      "backend"
    ]
    [
      "bash"
      "fish"
      "nushell"
    ]
)
// prefixed "notifications" (
  backendsOf
    [
      "my"
      "notifications"
      "backend"
    ]
    [
      "dunst"
      "mako"
    ]
)
// prefixed "file-manager" (
  backendsOf
    [
      "my"
      "file-manager"
      "backend"
    ]
    [
      "thunar"
      "nautilus"
      "dolphin"
      "pcmanfm"
    ]
)
// prefixed "module" (
  lib.genAttrs [
    "autorandr"
    "flatpak"
    "kanshi"
    "picom"
    "polybar"
    "waybar"
    "x11"
    "zellij"
  ] (m: variant { my.${m}.enable = true; })
)
