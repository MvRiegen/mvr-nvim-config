require("config.lazy")
require("config.keymaps")
require("config.telescope")

-- general settings

-- line numbering
vim.wo.number = true

-- UI tweaks for a VSCode-like look
vim.opt.laststatus = 3 -- global statusline
vim.opt.fillchars:append({ eob = " " }) -- hide ~ on empty lines
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"

-- Highlight yank for feedback
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Diagnostics tuning
vim.diagnostic.config({
  virtual_text = { severity = vim.diagnostic.severity.WARN },
  float = { border = "rounded" },
  update_in_insert = false,
})
