local neotest = require('neotest')
local keymaps = require('editor/keymappings')
local dapgo = require('dap-go')
dapgo.setup {}

neotest.setup({
  adapters = {
    require("neotest-go")({
      dap = { justMyCode = false },
    }),
    require("neotest-plenary"),
  },
})

keymaps.lsp_file_tests(function() neotest.run.run(vim.fn.expand("%")) end)
keymaps.lsp_nearest_test(function() neotest.run.run() end)
keymaps.lsp_debug_nearest_test(function() neotest.run.run({ strategy = "dap" }) end)

keymaps.lsp_toggle_test_tree(function() neotest.summary.toggle() end)
keymaps.lsp_toggle_test_output(function() neotest.output.open() end)
keymaps.lsp_toggle_breakpoint(function() vim.cmd('DapToggleBreakpoint') end)
