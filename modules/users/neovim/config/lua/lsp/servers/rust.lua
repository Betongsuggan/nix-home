local rt = require('rust-tools')

return function(on_attach, capabilities)
  local opts = {
    tools = {
      runnables = {
        use_telescope = true,
      },
      inlay_hints = {
        auto = true,
        show_parameter_hints = false,
        parameter_hints_prefix = "",
        other_hints_prefix = "",
      },
    },
    server = {
      on_attach = on_attach,
      capabilities = capabilities,
      standalone = true,
      settings = {
      },
    },
  }

  rt.setup(opts)
end
