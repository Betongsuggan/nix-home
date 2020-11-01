{
  xresources.extraConfig = ''
    ! -----------------------------------------------------------------------------
    ! File: gruvbox-dark.xresources
    ! Description: Retro groove colorscheme generalized
    ! Author: morhetz <morhetz@gmail.com>
    ! Source: https://github.com/morhetz/gruvbox-generalized
    ! Last Modified: 6 Sep 2014
    ! -----------------------------------------------------------------------------

    ! hard contrast: *background: #1d2021
    *background: #282828
    ! soft contrast: *background: #32302f
    *foreground: #ebdbb2
    ! Black + DarkGrey
    *color0:  #282828
    *color8:  #928374
    ! DarkRed + Red
    *color1:  #cc241d
    *color9:  #fb4934
    ! DarkGreen + Green
    *color2:  #98971a
    *color10: #b8bb26
    ! DarkYellow + Yellow
    *color3:  #d79921
    *color11: #fabd2f
    ! DarkBlue + Blue
    *color4:  #458588
    *color12: #83a598
    ! DarkMagenta + Magenta
    *color5:  #b16286
    *color13: #d3869b
    ! DarkCyan + Cyan
    *color6:  #689d6a
    *color14: #8ec07c
    ! LightGrey + White
    *color7:  #a89984
    *color15: #ebdbb2


    ! --- Urxvt config
    URxvt.scrollBar:   false
    URxvt.cursorBlink: true

    ! --- Set Ctrl + Shift + c/v for copy/paste
    URxvt.keysym.Shift-Control-V: eval:paste_clipboard
    URxvt.keysym.Shift-Control-C: eval:selection_to_clipboard
    URxvt.iso14755:               false
    URxvt.iso14755_52:            false

    ! --- Font setup
    URxvt.font:           xft:Hasklug Nerd Font Mono,Hasklig Medium:style=Medium,Regular:pixelsize=11
    URxvt.boldFont:       xft:Hasklug Nerd Font Mono:style=Bold:pixelsize=15
    URxvt.italicFont:     xft:Hasklug Nerd Font Mono:style=Italic:pixelsize=15
    URxvt.boldItalicFont: xft:Hasklug Nerd Font Mono:style=Bold Italic:pixelsize=15

    Xft*antialias:        true
  '';
}