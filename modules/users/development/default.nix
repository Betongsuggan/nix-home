{ config, pkgs, lib, ... }:
with lib;

{
  options.development = {
    enable = mkEnableOption "Enable development toolings";
  };

  config = mkIf config.development.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        altair
        openjdk17-bootstrap
        android-studio
        awscli2
        cabal-install
        docker-compose
        gnumake
        ghc
        jetbrains.idea-community
        jq
        kotlin
        newman
        nodejs-18_x
        yarn
        python3
        postman
        silver-searcher
        teleport
        terraform

        # Rust packages
        cargo
        rustc
        rustfmt

        # Go packages
        golangci-lint
        golangci-lint-langserver
        gotools
        delve
      ];
      programs.go.enable = true;

      home.sessionVariables = {
        JAVA_HOME = "${pkgs.openjdk17-bootstrap}";
        PATH = "$HOME/node_modules/bin:$PATH";
      };
    };
    unfreePackages = [ "postman" "terraform" "android-studio-stable" "idea-community" ];
  };
}
