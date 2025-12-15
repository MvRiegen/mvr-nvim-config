return {
  'nvim-telescope/telescope.nvim',
  version = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  }
}
