return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local ensure = {
      -- formatters
      "stylua",
      "ruff",
      "phpcbf",
      "rubocop",
      "prettier",
      -- linters
      "luacheck",
      "phpcs",
      "markdownlint",
    }

    -- Skip npm-based tools if npm isn't available
    if vim.fn.executable("npm") == 0 then
      local filtered = {}
      for _, tool in ipairs(ensure) do
        if tool ~= "prettier" and tool ~= "markdownlint" then
          table.insert(filtered, tool)
        end
      end
      ensure = filtered
    end

    require("mason-tool-installer").setup({
      ensure_installed = ensure,
      run_on_start = true,
      start_delay = 3000,
    })
  end,
}
