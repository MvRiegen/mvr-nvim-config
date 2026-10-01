return {
  "coffebar/neovim-project",
  opts = function()
    local clean_session = require("config.startup").clean_session_requested()

    return {
      projects = {
        "~/git/*",
        "~/.config/*",
        "~/prod*",
      },
      picker = {
        type = "telescope",
      },
      -- Reuse the plugin's own startup gate to suppress any automatic
      -- session restore when requested from the command line.
      dashboard_mode = clean_session,
      -- Show the dashboard instead of restoring the most recent session
      -- when nvim is started outside of a project directory.
      last_session_on_startup = false,
    }
  end,
  init = function()
    -- enable saving state plugins in session
    vim.opt.sessionoptions:append("globals")
  end,
  config = function(_, opts)
    require("config.session_manager").patch_load_session()
    require("neovim-project").setup(opts)
  end,
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    -- optional picker
    { "nvim-telescope/telescope.nvim", version = "0.2.2" },
    -- optional picker
    { "ibhagwan/fzf-lua" },
    { "Shatur/neovim-session-manager" },
  },
  event = "VimEnter",
  priority = 100,
}
