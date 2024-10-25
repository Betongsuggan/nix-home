vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]

-- Define custom diagnostic signs with icons
local signs = { Error = "🚨", Warn = "⚠️ ", Hint = "💡", Info = "💬" }

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = "SignColumn", linehl = "", numhl = "" })
end

vim.fn.sign_define('LightBulbSign', { text = "💡", texthl = "LightBulbSignColor", linehl = "", numhl = "" })

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  update_in_insert = true,
  underline = true,
  severity_sort = false,
  float = {
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
  },
})
