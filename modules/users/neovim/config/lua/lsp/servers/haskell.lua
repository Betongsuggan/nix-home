local ht = require('haskell-tools')

return function(on_attach, capabilities)
  ht.setup {
    hls = {
      on_attach = on_attach,
      capabilities = capabilities
    }
  }
end
