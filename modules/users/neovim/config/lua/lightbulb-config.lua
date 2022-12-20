local util = require('util')

-- Setup lightbulb sign to indicate a code action is available
vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]

-- Change to yellow lightbulb icon
util.colorize({
    LightBulbSignColor = { fg = "#FFFF00" }
})
vim.fn.sign_define('LightBulbSign', { text = "", texthl = "LightBulbSignColor", linehl="", numhl="" })
