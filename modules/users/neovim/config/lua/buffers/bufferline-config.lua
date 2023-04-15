-- Configuration for handling buffers

local keymaps = require('editor/keymappings')

require("bufferline").setup{
    options = {
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        diagnostics = "nvim_lsp",
    }
}

local function split_buffer(direction)
  vim.cmd(direction)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_buf(win, buf)
end

keymaps.next_buffer('<cmd>BufferLineCycleNext<cr>')
keymaps.previous_buffer('<cmd>BufferLineCyclePrev<cr>')

keymaps.split_buffer_vertically(function() split_buffer('vsplit') end)
keymaps.split_buffer_horizontally(function() split_buffer('split') end)

keymaps.move_to_buffer_left(function() vim.cmd('wincmd h') end)
keymaps.move_to_buffer_down(function() vim.cmd('wincmd j') end)
keymaps.move_to_buffer_up(function() vim.cmd('wincmd k') end)
keymaps.move_to_buffer_right(function() vim.cmd('wincmd l') end)

keymaps.sort_buffer_by_extension('<cmd>BufferLineSortByExtension<cr>')
keymaps.sort_buffer_by_directory('<cmd>BufferLineSortByDirectory<cr>')
