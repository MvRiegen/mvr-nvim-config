return {
  "folke/neoconf.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("neoconf").setup({})
  end,
}
