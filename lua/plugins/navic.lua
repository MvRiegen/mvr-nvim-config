return {
  "SmiteshP/nvim-navic",
  dependencies = { "neovim/nvim-lspconfig" },
  event = "LspAttach",
  opts = {
    lsp = {
      auto_attach = true,
    },
    highlight = true,
    separator = " > ",
  },
}
