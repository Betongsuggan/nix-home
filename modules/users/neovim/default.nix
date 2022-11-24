{ config, pkgs, lib, ... }:
let
  cfg = config.br.neovim;
in
{
  options.br.neovim = {
    enable = lib.mkEnableOption "Enable the vim editor";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR="nvim";
    };
    programs.neovim = {
      enable = true;
      extraConfig = " 
        set nocompatible
        set relativenumber
        syntax on
        set nowrap
        set encoding=utf8
        set hidden
 
        set nobackup
        set nowritebackup
        set updatetime=100
        set ttimeout
        set timeoutlen=1000
        set ttimeoutlen=5

        \" Show linenumbers
        set number
        set ruler
  
        \" Set Proper Tabs
        set tabstop=2
        set shiftwidth=2
        set smarttab
        set expandtab
  
        \" Always display the status line
        set laststatus=2
  
        colorscheme gruvbox
        \"let g:lightline.colorscheme = 'gruvbox'
        let g:VIM_COLOR_SCHEME = 'gruvbox'

        \" --- Auto commands
        autocmd FileType c,cpp,java,php,json :autocmd BufWritePre <buffer> %s/\s\+$//e

      ";
      plugins = with pkgs.vimPlugins; [
        # Developer plugins
        coc-nvim
        coc-yaml
        coc-json
        vim-nix
        nerdtree

        # Themes
        gruvbox
      ];
    };    
  };
}
