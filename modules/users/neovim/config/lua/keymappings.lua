local legendary = require('legendary')

local function add_key_mapping(keymap, opts, description)
  return function(command)  legendary.keymap({ keymap, command, opts = opts, description = description }) end
end

local search_opts = { silent = true, noremap = true }
local lsp_opts = { noremap=true, silent=true, buffer=true }
local key_mappings = {
  -- File tree mappings
  open_file_tree            = add_key_mapping('<leader>tt', { silent = true }, 'FileTree: Toggle File Tree'),
  refresh_file_in_tree      = add_key_mapping('<leader>tr', { silent = true }, 'FileTree: Refresh File Tree'),
  find_file_in_tree         = add_key_mapping('<leader>tf', { silent = true }, 'FileTree: Find File'),

  -- Buffers
  sort_buffer_by_extension  = add_key_mapping('<leader>se', { noremap = true }, 'Buffer: Sort buffers by extension'),
  sort_buffer_by_directory  = add_key_mapping('<leader>sd', { noremap = true }, 'Buffer: Sort buffers by directory'),

  split_buffer_horizontally = add_key_mapping('<leader>-', { noremap = true }, 'Buffer: Split buffer horizontally'),
  split_buffer_vertically   = add_key_mapping('<leader>|', { noremap = true }, 'Buffer: Split buffer vertically'),

  move_to_buffer_up         = add_key_mapping('<C-k>', { silent = true, noremap = true }, 'Buffer: Move to buffer above'),
  move_to_buffer_down       = add_key_mapping('<C-j>', { silent = true, noremap = true }, 'Buffer: Move to buffer below'),
  move_to_buffer_left       = add_key_mapping('<C-h>', { silent = true, noremap = true }, 'Buffer: Move to buffer to the left'),
  move_to_buffer_right      = add_key_mapping('<C-l>', { silent = true, noremap = true }, 'Buffer: Move to buffer to the right'),

  next_buffer               = add_key_mapping('<leader>l', { noremap = true }, 'Buffer: Next buffer'),
  previous_buffer           = add_key_mapping('<leader>h', { noremap = true }, 'Buffer: Previous buffer'),
  close_buffer              = add_key_mapping('<leader>q', { noremap = true }, 'Buffer: Close buffer')(':bd <CR>'),

  -- Searching
  search_file_name          = add_key_mapping('<leader>ff', search_opts, 'Searching: Search file name'),
  search_directory_contents = add_key_mapping('<leader>fg', search_opts, 'Searching: Search directory contents'),
  search_buffer_names       = add_key_mapping('<leader>fb', search_opts, 'Searching: Search buffer names'),
  search_help_tags          = add_key_mapping('<leader>fh', search_opts, 'Searching: Search help tags'),

  -- LSP mappings
  lsp_go_to_declaration     = add_key_mapping('gD', lsp_opts, 'LSP: Go to declaration'),
  lsp_go_to_definition      = add_key_mapping('gd', lsp_opts, 'LSP: Go to definition'),
  lsp_go_to_implementation  = add_key_mapping('gi', lsp_opts, 'LSP: Go to implementation'),

  lsp_next_reference        = add_key_mapping(']u', lsp_opts, 'LSP: Next reference'),
  lsp_previous_reference    = add_key_mapping('[u', lsp_opts, 'LSP: Previous reference'),
  lsp_next_diagnostic       = add_key_mapping(']d', lsp_opts, 'LSP: Next diagnostic'),
  lsp_previous_diagnostic   = add_key_mapping('[d', lsp_opts, 'LSP: Previous diagnostic'),

  lsp_hover                 = add_key_mapping('<leader>nh', lsp_opts, 'LSP: Hover'),
  lsp_rename                = add_key_mapping('<leader>nn', lsp_opts, 'LSP: Rename'),
  lsp_format                = add_key_mapping('<leader>nf', lsp_opts, 'LSP: Format'),

  lsp_show_signature        = add_key_mapping('<leader>ns', lsp_opts, 'LSP: Show signature'),
  lsp_show_type_definition  = add_key_mapping('<leader>nt', lsp_opts, 'LSP: Show type definition'),
  lsp_show_code_action      = add_key_mapping('<leader>na', lsp_opts, 'LSP: Show code action'),
  lsp_show_diagnostics      = add_key_mapping('<leader>ne', lsp_opts, 'LSP: Show diagnostics'),
  lsp_show_references       = add_key_mapping('<leader>nr', lsp_opts, 'LSP: Show references'),

--        { '<space>wa', vim.lsp.buf.add_workspace_folder, description = 'LSP: Add workspace folder', opts = opts },
--        { '<space>wr', vim.lsp.buf.remove_workspace_folder, description = 'LSP: Remove workspace folder', opts = opts },
--        { '<space>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, description = 'LSP: List workspaces', opts = opts },
}
return key_mappings
