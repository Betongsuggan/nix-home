local nvim_lsp = require('lspconfig')

return function(on_attach, capabilities)
  nvim_lsp.java_language_server.setup {
    cmd = { 'java-language-server' },
    on_attach = on_attach,
    capabilities = capabilities
  }
end
