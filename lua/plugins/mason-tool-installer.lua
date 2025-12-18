return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  event = "VeryLazy",
  config = function()
    local ensure = {
      -- formatters
      "stylua",
      "ruff",
      "phpcbf",
      "rubocop",
      "prettier",
      "xmlformatter",
      -- linters
      "luacheck",
      "phpcs",
      "markdownlint",
      "yamllint",
      "jsonlint",
      "eslint_d",
      "htmlhint",
    }

    -- Skip npm-based tools if npm isn't available
    if vim.fn.executable("npm") == 0 then
      local npm_tools = {
        prettier = true,
        markdownlint = true,
        jsonlint = true,
        eslint_d = true,
        xmlformatter = true,
        htmlhint = true,
      }
      local filtered = {}
      for _, tool in ipairs(ensure) do
        if not npm_tools[tool] then
          table.insert(filtered, tool)
        end
      end
      ensure = filtered
    end

    local ok_registry, registry = pcall(require, "mason-registry")
    if ok_registry then
      local filtered = {}
      for _, tool in ipairs(ensure) do
        if registry.has_package(tool) then
          table.insert(filtered, tool)
        end
      end
      ensure = filtered
    end

    require("mason-tool-installer").setup({
      ensure_installed = ensure,
      run_on_start = true,
      start_delay = 6000,
    })
  end,
}
