-- Visualizes space characters and indentation coloumns

vim.opt.list = true
--vim.opt.listchars:append "space:⋅"
--vim.opt.termguicolors = true

vim.cmd [[highlight IndentBlanklineIndent1 guibg=#282828 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guibg=#222222 gui=nocombine]]

require("indent_blankline").setup {
  char = " ",
  char_highlight_list = {
    "IndentBlanklineIndent1",
    "IndentBlanklineIndent2",
  },
  space_char_highlight_list = {
    "IndentBlanklineIndent1",
    "IndentBlanklineIndent2",
  },
  show_trailing_blankline_indent = false,
  --show_current_context = true,
}
