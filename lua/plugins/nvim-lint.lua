return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local linters = {
      lua = { "luacheck" },
      python = { "ruff" },
      php = { "phpcs" },
      markdown = { "markdownlint" },
      puppet = { "puppet-lint" },
      ruby = { "rubocop" },
      yaml = { "yamllint" },
      json = { "jsonlint" },
      typescript = { "eslint_d" },
    }
    if lint.linters.xmllint then
      linters.xml = { "xmllint" }
    end
    if lint.linters.htmlhint then
      linters.html = { "htmlhint" }
    end
    lint.linters_by_ft = linters

    local function try_lint()
      lint.try_lint()
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
      callback = try_lint,
    })
  end,
}
