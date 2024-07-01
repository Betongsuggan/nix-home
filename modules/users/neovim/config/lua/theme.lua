local backgroundLight = "#191b1d"
local backgroundDark  = "#111213"
local borderLight     = "#5e5f60"
local borderDark      = "#111213"
local textLight       = "#ffffff"
local textMid         = "#acacac"
local textDark        = "#161516"
local yellowLight     = "#f1f252"
local yellowDark      = "#1c1d16"
local redLight        = "#ff5151"
local redDark         = "#1d1516"
local organgeLight    = "#71e59f"
local organgeDark     = "#1d1a17"
local purpleLight     = "#7f71e5"
local purpleDark      = "#1f2027"
local blueLight       = "#71e59f"
local blueDark        = "#151a1e"
local greenLight      = "#71e59f"
local greenDark       = "#151c1a"

local function set_highlights()
    local cmd = vim.cmd

    -- Clear existing highlights and set the default background to dark
    cmd 'highlight clear'
    vim.o.background = 'dark'
    cmd 'syntax reset'

    -- Define highlight groups
    cmd('highlight Title guifg=' .. organgeLight)
    cmd('highlight Directory guifg=' .. organgeLight)
    cmd('highlight Normal guifg=' .. textLight .. ' guibg=' .. backgroundDark)
    cmd('highlight Error guifg=' .. redLight .. ' guibg=' .. backgroundDark)
    cmd('highlight StatusLine guifg=' .. textLight .. ' guibg=' .. backgroundDark)
    cmd('highlight ScrollBar guifg=' .. textLight .. ' guibg=' .. backgroundLight)
    cmd('highlight SignColumn guifg=' .. textLight .. ' guibg=' .. backgroundDark)

    cmd('highlight Pmenu guifg=' .. textLight .. ' guibg=' .. backgroundDark)
    cmd('highlight BufferlienTab guifg=' .. textLight .. ' guibg=' .. backgroundDark)

    cmd('highlight CursorLine guibg=' .. backgroundLight)
    cmd('highlight Visual guifg=' .. backgroundDark .. ' guibg=' .. borderLight)
    cmd('highlight LineNr guifg=' .. textMid .. ' guibg=' .. backgroundDark)

    cmd('highlight Comment guifg=' .. borderLight)

    cmd('highlight Identifier guifg=' .. textLight)
    cmd('highlight Constant guifg=' .. blueLight)
    cmd('highlight Function guifg=' .. purpleLight)
    cmd('highlight Statement guifg=' .. redLight)

    cmd('highlight Operator guifg=' .. textLight)
    cmd('highlight Struct guifg=' .. organgeLight)

    cmd('highlight Type guifg=' .. organgeLight)
    cmd('highlight StorageClass guifg=' .. organgeLight)
    cmd('highlight Structure guifg=' .. organgeLight)
    cmd('highlight Typedef guifg=' .. organgeLight)

    --cmd('highlight @lsp.type.class guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.type guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.method guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.struct guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.comment guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.function guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.property guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.variable guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.decorator guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.namespace guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.parameter guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.enumMember guifg=' .. "#ff0000")
    --cmd('highlight @lsp.type.typeParameter guifg=' .. "#ff0000")
end

-- Apply the highlights when the file is loaded
set_highlights()
vim.cmd([[ autocmd ColorScheme * :lua require('vim.lsp.diagnostic')._define_default_signs_and_highlights() ]]) 

require("gruvbox").setup({
    palette_overrides = {
        --dark0_hard       = backgroundLight,
        --dark0            = backgroundLight,
        --dark0_soft       = backgroundLight,
        --dark1            = backgroundLight,
        --dark2            = backgroundLight,
        --dark3            = backgroundLight,
        --dark4            = backgroundLight,
        --light0_hard      = textLight,
        --light0           = textLight,
        --light0_soft      = textMid,
        --light1           = textLight,
        --light2           = textLight,
        --light3           = textLight,
        --light4           = textLight,
        --bright_red       = redLight,
        --bright_green     = greenLight,
        --bright_yellow    = yellowLight,
        --bright_blue      = blueLight,
        --bright_purple    = purpleLight,
        --bright_aqua      = blueLight,
        --bright_orange    = organgeLight,
        --neutral_red      = redLight,
        --neutral_green    = greenLight,
        --neutral_yellow   = yellowLight,
        --neutral_blue     = blueLight,
        --neutral_purple   = purpleLight,
        --neutral_aqua     = blueLight,
        --neutral_orange   = organgeLight,
        --faded_red        = redDark,
        --faded_green      = greenDark,
        --faded_yellow     = yellowDark,
        --faded_blue       = blueDark,
        --faded_purple     = purpleDark,
        --faded_aqua       = blueDark,
        --faded_orange     = organgeDark,
        --dark_red_hard    = redDark,
        --dark_red         = redDark,
        --dark_red_soft    = redDark,
        --light_red_hard   = redLight,
        --light_red        = redLight,
        --light_red_soft   = redLight,
        --dark_green_hard  = greenDark,
        --dark_green       = greenDark,
        --dark_green_soft  = greenDark,
        --light_green_hard = greenLight,
        --light_green      = greenLight,
        --light_green_soft = greenLight,
        --dark_aqua_hard   = blueDark,
        --dark_aqua        = blueDark,
        --dark_aqua_soft   = blueDark,
        --light_aqua_hard  = blueLight,
        --light_aqua       = blueLight,
        --light_aqua_soft  = blueLight,
        --gray             = textMid,
    }
})
--vim.cmd([[ colorscheme gruvbox ]])
