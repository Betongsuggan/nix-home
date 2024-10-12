-- Configuration for searching for files and content
local keymaps = require('editor/keymappings')
local telescope = require('telescope')
local builtins = require('telescope.builtin')
telescope.setup({})

keymaps.search_file_name(builtins.find_files)
keymaps.search_directory_contents(builtins.live_grep)
keymaps.search_symbols(builtins.lsp_dynamic_workspace_symbols)
keymaps.search_buffer_names(builtins.buffers)
keymaps.search_help_tags(builtins.help_tags)
