vim.opt.mouse = "a"

-- Nvim-Tree
vim.keymap.set("n","<leader>s",":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "NvimTree toggle" })
vim.keymap.set("n","<leader>d",":NvimTreeFocus<CR>", { noremap = true, silent = true, desc = "NvimTree focus" })
vim.keymap.set("n","<leader>c",":NvimTreeClose<CR>", { noremap = true, silent = true, desc = "NvimTree close" })

-- Nvim-Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Live grep" })

vim.keymap.set('n', '<leader>fd', builtin.buffers, { desc = "Buffers" })

-- Quick quit: close NvimTree if open, then quit all
local function smart_quit()
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    api.tree.close()
  end
  vim.cmd("qa")
end
vim.keymap.set('n', '<leader>qq', smart_quit, { desc = "Quit all (close tree)" })
