-- Mouse
vim.opt.mouse = "a"

-- Nvim-Tree
vim.keymap.set("n","<leader>s",":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n","<leader>d",":NvimTreeFocus<CR>", { noremap = true, silent = true })
vim.keymap.set("n","<leader>c",":NvimTreeClose<CR>", { noremap = true, silent = true })

-- Nvim-Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fd', builtin.buffers, {})
