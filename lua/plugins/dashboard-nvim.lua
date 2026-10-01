return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  config = function()
    -- hyper.lua crashes on <CR> over lines without punctuation (e.g. the
    -- "empty project"/"empty files" placeholders) on Windows, so skip those.
    vim.api.nvim_create_autocmd("User", {
      pattern = "DashboardLoaded",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local original = vim.fn.maparg("<CR>", "n", false, true)
        if type(original.callback) ~= "function" then
          return
        end
        vim.keymap.set("n", "<CR>", function()
          local line = vim.api.nvim_get_current_line()
          if line:find("empty project") or line:find("empty files") or not line:find("%p") then
            return
          end
          original.callback()
        end, { buffer = buf, nowait = true, silent = true })
      end,
    })

    require("dashboard").setup({
      theme = "hyper",
      config = {
        week_header = {
          enable = true,
        },
        shortcut = {
          { desc = "[U] Update", group = "@property", action = "Lazy update", key = "u" },
          {
            icon = "[F]",
            icon_hl = "@variable",
            desc = "Files",
            group = "Label",
            action = "Telescope find_files",
            key = "f",
          },
        },
      },
    })
  end,
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
  },
}
