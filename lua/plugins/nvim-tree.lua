return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  config = function()
    -- disable netrw for better compatibility
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    require("nvim-tree").setup({
      actions = {
        open_file = {
          quit_on_open = false, -- keep tree open when opening/closing buffers
        },
      },
    })
  end,
}
