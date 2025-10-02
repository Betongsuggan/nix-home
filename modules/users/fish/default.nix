{ pkgs, config, lib, ... }:
with lib;

{
  options.fish = {
    enable = mkOption {
      description = "Enable fish shell";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.fish.enable {
    programs = {
      nix-index = {
        enable = true;
        enableFishIntegration = true;
      };
      fish = {
        enable = true;
        shellAliases = {
          cloud = "cd ~/Development/cloud";
          dashboard = "cd ~/Development/web/apps/dashboard";
          nocode = "cd ~/Development/web/apps/nocode";
          demo = "cd ~/Development/web/apps/nocode-demo";
          ll = "ls -la --color=auto";
          ls = "ls --color=auto";
          vim = "nvim";
          hm = "home-manager";
          gw = "./gradlew --no-daemon";
        };
        shellInit = ''
          export EDITOR=nvim
          export PATH="$PATH:~/.cargo/bin/"
          export ANTHROPIC_API_KEY="$(ai_key_provider)"

          fish_vi_key_bindings
        '';
      };
    };
  };
}
