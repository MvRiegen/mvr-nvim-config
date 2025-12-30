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

      local ok_registry, registry = pcall(require, "mason-registry")
      if not ok_registry then
        return
      end

      local refreshed = false
      registry.refresh(function()
        refreshed = true
      end)
      vim.wait(60000, function()
        return refreshed
      end, 100)

      local pending = 0
      local to_install = {}
      local done = false

      local function finalize()
        done = true
      end

      for _, name in ipairs(tools) do
        local ok_pkg, pkg = pcall(registry.get_package, name)
        if ok_pkg then
          if not pkg:is_installed() then
            table.insert(to_install, name)
          else
            if type(pkg.check_new_version) == "function" then
              pending = pending + 1
              pkg:check_new_version(function(success)
                if success then
                  table.insert(to_install, name)
                end
                pending = pending - 1
                if pending == 0 then
                  finalize()
                end
              end)
            end
          end
        end
      end

      if pending == 0 then
        finalize()
      else
        vim.wait(60000, function()
          return done
        end, 100)
      end

      if #to_install == 0 then
        return
      end

      vim.cmd("MasonInstall --sync " .. table.concat(to_install, " "))
    end, {})

    require("mason-tool-installer").setup({
      ensure_installed = filtered_tools(),
      run_on_start = true,
      start_delay = 2000,
    })
  end,
}
