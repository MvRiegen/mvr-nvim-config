require("lazy").setup({
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
	open_mapping = [[<c-\>]],
        shade_terminals = false,
        shell = "zsh --login",
      })
    end
  }
})
