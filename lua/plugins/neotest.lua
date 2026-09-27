return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-plenary",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-plenary"),
      },
    })
  end,
  keys = {
    {
      "<leader>xs",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Test explorer (Neotest)",
    },
  },
}
