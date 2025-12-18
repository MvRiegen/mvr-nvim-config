return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        -- formatters
        "stylua",
        "ruff",
        "phpcbf",
        "rubocop",
        "prettier",
        -- linters
        "luacheck",
        "phpcs",
        "puppet-lint",
        "markdownlint",
      },
      run_on_start = true,
      start_delay = 3000,
    })
  end,
}
