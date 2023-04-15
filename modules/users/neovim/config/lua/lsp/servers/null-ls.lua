local null_ls = require("null-ls")

return function(on_attach, capabilities)
  null_ls.setup({
    sources = {
      -- Nix
      null_ls.builtins.formatting.nixpkgs_fmt,
      null_ls.builtins.diagnostics.statix,
      null_ls.builtins.code_actions.statix,
    },
  })
end
