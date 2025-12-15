return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  keys = {
    { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todos (Trouble)" },
    { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todos (Telescope)" },
  },
}
