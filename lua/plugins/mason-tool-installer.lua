return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  lazy = false,
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

    local function filtered_tools()
      local tools = vim.deepcopy(ensure)

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
        for _, tool in ipairs(tools) do
          if not npm_tools[tool] then
            table.insert(filtered, tool)
          end
        end
        tools = filtered
      end

      local ok_registry, registry = pcall(require, "mason-registry")
      if ok_registry then
        local filtered = {}
        for _, tool in ipairs(tools) do
          if registry.has_package(tool) then
            table.insert(filtered, tool)
          end
        end
        tools = filtered
      end

      return tools
    end

    vim.api.nvim_create_user_command("MasonToolsInstallSync", function()
      local tools = filtered_tools()
      if #tools == 0 then
        return
      end
      vim.cmd("MasonUpdate")
      vim.cmd("MasonInstall --sync " .. table.concat(tools, " "))
    end, {})

    require("mason-tool-installer").setup({
      ensure_installed = filtered_tools(),
      run_on_start = true,
      start_delay = 2000,
    })
  end,
}
