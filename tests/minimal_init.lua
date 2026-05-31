local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h")
local plenary_path = vim.env.PLENARY_PATH or (vim.fn.stdpath("data") .. "/lazy/plenary.nvim")

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(plenary_path)

package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")
