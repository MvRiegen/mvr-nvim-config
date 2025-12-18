return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  config = function()
    -- disable netrw for better compatibility
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    require("nvim-tree").setup({
      view = {
        width = 30,
      },
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          show = {
            folder_arrow = false,
          },
        },
      },
      actions = {
        open_file = {
          quit_on_open = false, -- keep tree open when opening/closing buffers
        },
      },
    })

    -- Keymaps via API for reliability
    local api = require("nvim-tree.api")
    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<leader>s", api.tree.toggle, vim.tbl_extend("force", opts, { desc = "NvimTree toggle" }))
    vim.keymap.set("n", "<leader>d", api.tree.focus, vim.tbl_extend("force", opts, { desc = "NvimTree focus" }))
    vim.keymap.set("n", "<leader>c", api.tree.close, vim.tbl_extend("force", opts, { desc = "NvimTree close" }))
  end,
}
