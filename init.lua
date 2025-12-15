require("config.lazy")
require("config.keymaps")
require("config.telescope")

-- general settings

-- line numbering
vim.wo.number = true

-- UI tweaks for a VSCode-like look
vim.opt.laststatus = 3 -- global statusline
vim.opt.fillchars:append({ eob = " " }) -- hide ~ on empty lines
