return {
  "coffebar/neovim-project",
  opts = {
    projects = {
      "~/git/*",
      "~/.config/*",
      "~/prod*",
    },
    picker = {
      type = "telescope",
    }
  },
  init = function()
    -- enable saving the state of plugins in the session
    vim.opt.sessionoptions:append("globals")
  end,
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    -- optional picker
    { "nvim-telescope/telescope.nvim", version = "0.1.8" },
    -- optional picker
    { "ibhagwan/fzf-lua" },
    { "Shatur/neovim-session-manager" },
  },
  event = "VimEnter",
  priority = 100,
}
