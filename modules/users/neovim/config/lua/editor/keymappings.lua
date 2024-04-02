local legendary = require('legendary')

local function add_key_mapping(keymap, opts, description)
  return function(command) legendary.keymap({ keymap, command, opts = opts, description = description }) end
end

local search_opts = { silent = true, noremap = true }
local lsp_opts = { noremap = true, silent = true, buffer = true }
local key_mappings = {
  -- File tree mappings
  open_file_tree            = add_key_mapping('<leader>tt', { silent = true }, 'FileTree: Toggle File Tree'),
  refresh_file_in_tree      = add_key_mapping('<leader>tr', { silent = true }, 'FileTree: Refresh File Tree'),
  find_file_in_tree         = add_key_mapping('<leader>tf', { silent = true }, 'FileTree: Find File'),

  -- Autocompletion
  -- These are now setup in cmp-config.lua since I haven't gottem them to work through legendary
  --autocomplete              = add_key_mapping('<C-Space>',{ silent = true, noremap = true }, 'Show autocomplete options'),
  --autocomplete_confirm      = add_key_mapping('<CR>', { silent = true, noremap = true }, 'Select autocomplete option'),
  --autocomplete_next         = add_key_mapping('<Tab>', { silent = true, noremap = true }, 'Show next autocomplete option'),
  --autocomplete_previous     = add_key_mapping('<S-Tab>', { silent = true, noremap = true }, 'Show previous autocomplete option'),

  -- Buffers
  sort_buffer_by_extension  = add_key_mapping('<leader>se', { noremap = true }, 'Buffer: Sort buffers by extension'),
  sort_buffer_by_directory  = add_key_mapping('<leader>sd', { noremap = true }, 'Buffer: Sort buffers by directory'),
  split_buffer_horizontally = add_key_mapping('<leader>-', { noremap = true }, 'Buffer: Split buffer horizontally'),
  split_buffer_vertically   = add_key_mapping('<leader>|', { noremap = true }, 'Buffer: Split buffer vertically'),
  move_to_buffer_up         = add_key_mapping('<C-k>', { silent = true, noremap = true }, 'Buffer: Move to buffer above'),
  move_to_buffer_down       = add_key_mapping('<C-j>', { silent = true, noremap = true }, 'Buffer: Move to buffer below'),
  move_to_buffer_left       = add_key_mapping('<C-h>', { silent = true, noremap = true },
    'Buffer: Move to buffer to the left'),
  move_to_buffer_right      = add_key_mapping('<C-l>', { silent = true, noremap = true },
    'Buffer: Move to buffer to the right'),
  next_buffer               = add_key_mapping('<leader>l', { noremap = true }, 'Buffer: Next buffer'),
  previous_buffer           = add_key_mapping('<leader>h', { noremap = true }, 'Buffer: Previous buffer'),
  close_buffer              = add_key_mapping('<leader>q', { noremap = true }, 'Buffer: Close buffer')(':bd <CR>'),
  -- Searching
  search_file_name          = add_key_mapping('<leader>ff', search_opts, 'Searching: Search file name'),
  search_directory_contents = add_key_mapping('<leader>fg', search_opts, 'Searching: Search directory contents'),
  search_buffer_names       = add_key_mapping('<leader>fb', search_opts, 'Searching: Search buffer names'),
  search_symbols            = add_key_mapping('<leader>fn', search_opts, 'Searching: Search workspace symbols'),
  search_help_tags          = add_key_mapping('<leader>fh', search_opts, 'Searching: Search help tags'),
  -- LSP mappings
  lsp_go_to_declaration     = add_key_mapping('sD', lsp_opts, 'LSP: Go to declaration'),
  lsp_go_to_definition      = add_key_mapping('sd', lsp_opts, 'LSP: Go to definition'),
  lsp_go_to_implementation  = add_key_mapping('si', lsp_opts, 'LSP: Go to implementation'),
  lsp_next_reference        = add_key_mapping('so', lsp_opts, 'LSP: Next reference'),
  lsp_previous_reference    = add_key_mapping('sO', lsp_opts, 'LSP: Previous reference'),
  lsp_next_diagnostic       = add_key_mapping('su', lsp_opts, 'LSP: Next diagnostic'),
  lsp_previous_diagnostic   = add_key_mapping('sU', lsp_opts, 'LSP: Previous diagnostic'),
  -- These are now setup in cmp-config.lua since I haven't gottem them to work through legendary
  --lsp_scroll_docs_down      = add_key_mapping('<C-S-j>', lsp_opts, 'LSP: Scroll down in documentation'),
  --lsp_scroll_docs_up        = add_key_mapping('<C-S-k>', lsp_opts, 'LSP: Scroll up in documentation'),

  lsp_hover                 = add_key_mapping('sh', lsp_opts, 'LSP: Hover'),
  lsp_rename                = add_key_mapping('sn', lsp_opts, 'LSP: Rename'),
  lsp_format                = add_key_mapping('sl', lsp_opts, 'LSP: Format'),
  lsp_show_signature        = add_key_mapping('ss', lsp_opts, 'LSP: Show signature'),
  lsp_show_type_definition  = add_key_mapping('st', lsp_opts, 'LSP: Show type definition'),
  lsp_show_code_action      = add_key_mapping('sa', lsp_opts, 'LSP: Show code action'),
  lsp_show_diagnostics      = add_key_mapping('se', lsp_opts, 'LSP: Show diagnostic'),
  lsp_show_references       = add_key_mapping('sr', lsp_opts, 'LSP: Show references'),
  lsp_create_workspace      = add_key_mapping('swa', lsp_opts, 'LSP: Add workspace folder'),
  lsp_remove_workspace      = add_key_mapping('swd', lsp_opts, 'LSP: Remove workspace folder'),
  lsp_show_workspaces       = add_key_mapping('swl', lsp_opts, 'LSP: List workspaces'),

  -- LSP Testing
  lsp_file_tests            = add_key_mapping('smg', { noremap = true }, 'LSP: Run all tests in file'),
  lsp_nearest_test          = add_key_mapping('sme', { noremap = true }, 'LSP: Run nearest test'),
  lsp_debug_nearest_test    = add_key_mapping('smd', { noremap = true }, 'LSP: Debug nearest test'),
  lsp_toggle_test_output    = add_key_mapping('smo', { noremap = true }, 'LSP: Toggle debug menu'),
  lsp_toggle_test_tree      = add_key_mapping('smi', { noremap = true }, 'LSP: Toggle debug menu'),

  -- LSP Debugging
  lsp_toggle_breakpoint     = add_key_mapping('smb', { noremap = true }, 'LSP: Toggle breakpoint'),
}

key_mappings.lsp_format(
  function()
    vim.lsp.buf.format()
    vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
  end
)
return key_mappings
