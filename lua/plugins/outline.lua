return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  opts = {
    preview_window = {
      auto_preview = true,
    },
  },
  keys = {
    { "<leader>o", "<cmd>Outline<cr>", desc = "Symbols Outline" },
  },
}
