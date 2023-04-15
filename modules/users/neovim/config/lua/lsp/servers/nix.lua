local nvim_lsp = require('lspconfig')

return function(on_attach, capabilities)
  nvim_lsp.rnix.setup {
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)

      -- Let statix format
      client.server_capabilities.document_formatting = false
      client.server_capabilities.document_range_formatting = false
    end
  }
end
