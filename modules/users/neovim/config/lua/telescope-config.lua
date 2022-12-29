-- Telescope Settings
local keymaps = require('keymappings')
local telescope = require('telescope.builtin')

keymaps.search_file_name(telescope.find_files)
keymaps.search_directory_contents(telescope.live_grep)
keymaps.search_buffer_names(telescope.buffers)
keymaps.search_help_tags(telescope.help_tags)
