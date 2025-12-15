return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      lua = { "luacheck" },
      python = { "ruff" },
      php = { "phpcs" },
      markdown = { "markdownlint" },
      puppet = { "puppet-lint" },
      ruby = { "rubocop" },
    }

    local function try_lint()
      lint.try_lint()
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
      callback = try_lint,
    })
  end,
}
