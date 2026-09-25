# The editor: the nvim flake input (nixvim), built for this user's languages
# and colors.
{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.editor;
  dev = config.my.development;
  host = osConfig.my.common.host;
  flake = ''(builtins.getFlake "${cfg.flakePath}")'';
  schemes = import ../theming/schemes.nix;
in
{
  options.my.editor = {
    enable = lib.mkEnableOption "the nvim editor" // {
      default = config.my.shell.enable;
      defaultText = lib.literalExpression "config.my.shell.enable";
    };

    # A language brings its language server, formatter, tests and debugger
    languages =
      let
        language =
          name: default: defaultText:
          lib.mkOption {
            type = lib.types.bool;
            inherit default;
            defaultText = lib.literalMD defaultText;
            description = "${name} support in the editor";
          };
        developing =
          name: flag: language name dev.${flag}.enable "whether `my.development.${flag}` is enabled";
      in
      {
        # The admin accounts (lib.accounts) are the ones that edit this repo
        nix =
          language "Nix" (builtins.elem config.home.username osConfig.my.common.admins)
            "whether the user is an admin (`my.common.admins`)";
        go = developing "Go" "go";
        rust = developing "Rust" "rust";
        typescript = developing "TypeScript" "node";
        kotlin = developing "Kotlin" "kotlin";
      };

    flakePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${config.home.homeDirectory}/nix-home";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/nix-home"'';
      description = ''
        Checkout of this flake. nixd reads this host's NixOS and Home Manager
        options from it for completion and documentation; null turns that off.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.nvim-config.extend {
        languages = lib.recursiveUpdate (lib.mapAttrs (_: enable: { inherit enable; }) cfg.languages) {
          nix.nixd.options = lib.optionalAttrs (cfg.languages.nix && cfg.flakePath != null) {
            nixos = "${flake}.nixosConfigurations.${host}.options";
            home-manager = "${flake}.nixosConfigurations.${host}.options.home-manager.users.type.getSubOptions [ ]";
          };
        };
        # The desktop's color scheme, as its Neovim colorscheme plugin
        theme.colorscheme = lib.mkIf config.my.theming.enable schemes.${config.my.theming.scheme}.editor;
      })
    ];
  };
}
