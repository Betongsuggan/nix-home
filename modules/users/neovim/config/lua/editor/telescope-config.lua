-- Configuration for searching for files and content
local keymaps = require('editor/keymappings')
local telescope = require('telescope.builtin')

keymaps.search_file_name(telescope.find_files)
keymaps.search_directory_contents(telescope.live_grep)
keymaps.search_symbols(telescope.lsp_dynamic_workspace_symbols)
keymaps.search_buffer_names(telescope.buffers)
keymaps.search_help_tags(telescope.help_tags)
