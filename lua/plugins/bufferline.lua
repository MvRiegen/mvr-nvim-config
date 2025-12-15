return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      offsets = { { filetype = "NvimTree", text = "File Explorer", separator = true } },
      custom_filter = function(bufnr)
        -- hide NvimTree from the bufferline so its tab cannot be closed accidentally
        return vim.bo[bufnr].filetype ~= "NvimTree"
      end,
    },
  },
  keys = {
    { "<S-l>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    { "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
    { "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>", desc = "Buffer 1" },
    { "<leader>2", "<Cmd>BufferLineGoToBuffer 2<CR>", desc = "Buffer 2" },
    { "<leader>3", "<Cmd>BufferLineGoToBuffer 3<CR>", desc = "Buffer 3" },
    { "<leader>4", "<Cmd>BufferLineGoToBuffer 4<CR>", desc = "Buffer 4" },
  },
}
