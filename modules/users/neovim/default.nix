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
      extraConfig = ''
        filetype plugin indent on
        set termguicolors
        set cursorline
        set clipboard=unnamedplus
        set completeopt=noinsert,menuone,noselect
        set nocompatible
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
        set title
        set inccommand=split
        set splitbelow splitright
        set wildmenu

        " Show linenumbers
        set number
        set ruler
  
        " Set Proper Tabs
        set tabstop=2
        set shiftwidth=2
        set smarttab
        set expandtab
  
        " Always display the status line
        set laststatus=2
  
        colorscheme gruvbox
        "let g:lightline.colorscheme = 'gruvbox'
        let g:VIM_COLOR_SCHEME = 'gruvbox'

        " --- Auto commands
        autocmd FileType c,cpp,java,php,json :autocmd BufWritePre <buffer> %s/\s\+$//e

        " Airline configuration
        let g:airline_powerline_fonts = 1
        let g:airline#extensions#tabline#enabled = 1

        " NERDTree configuration
        let NERDTreeShowHidden = 1

        map <C-n> :NERDTreeToggle<CR>

        " CTRLP configuration
        let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
      '';
      plugins = with pkgs.vimPlugins; [
        # Developer plugins
        vim-nix

        # Navigation
        ctrlp
        nerdtree

        # Themes
        vim-airline
        vim-devicons
        gruvbox
      ];
    };
  };
}
