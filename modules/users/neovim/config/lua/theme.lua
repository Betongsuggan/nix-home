-- Define a table to hold your color values
local colors = {
    bg = '#282828',
    fg = '#ebdbb2',
    red = '#fb4934',
    comment = '#928374',
    identifier = '#fabd2f',
    constant = '#d3869b'
}

-- Define a function to set the highlight groups using your colors
local function set_highlights()
    local cmd = vim.cmd

    -- Clear existing highlights and set the default background to dark
    cmd 'highlight clear'
    vim.o.background = 'dark'
    cmd 'syntax reset'

    -- Define highlight groups
    cmd('highlight Normal guifg=' .. colors.fg .. ' guibg=' .. colors.bg)
    cmd('highlight Error guifg=' .. colors.red .. ' guibg=' .. colors.bg)
    cmd('highlight Comment guifg=' .. colors.comment)
    cmd('highlight Identifier guifg=' .. colors.identifier)
    cmd('highlight Constant guifg=' .. colors.constant)
end

-- Apply the highlights when the file is loaded
set_highlights()
