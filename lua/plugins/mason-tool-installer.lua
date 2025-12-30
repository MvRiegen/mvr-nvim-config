local tooling = require("config.tooling")

return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  lazy = false,
  config = function()
    local function log_line(msg)
      local path = vim.fn.stdpath("state") .. "/mason-tools-sync.log"
      vim.fn.writefile({ os.date("%F %T") .. " " .. msg }, path, "a")
    end

    local function refresh_registry()
      local ok_registry, registry = pcall(require, "mason-registry")
      if not ok_registry then
        return false
      end
      local refreshed = false
      registry.refresh(function()
        refreshed = true
      end)
      vim.wait(60000, function()
        return refreshed
      end, 100)
      return refreshed
    end

    local function filtered_tools(skip_registry)
      local tools = vim.deepcopy(tooling.mason_tools)

      -- Skip npm-based tools if npm isn't available
      if vim.fn.executable("npm") == 0 then
        local filtered = {}
        for _, tool in ipairs(tools) do
          if not tooling.npm_tools[tool] then
            table.insert(filtered, tool)
          end
        end
        tools = filtered
      end

      if not skip_registry then
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
      end

      return tools
    end

    vim.api.nvim_create_user_command("MasonToolsInstallSync", function()
      log_line("MasonToolsInstallSync start data_dir=" .. vim.fn.stdpath("data"))
      log_line("MasonToolsInstallSync npm=" .. tostring(vim.fn.executable("npm") == 1))
      local ok_registry, registry = pcall(require, "mason-registry")
      if not ok_registry then
        log_line("MasonToolsInstallSync registry missing")
        return
      end

      local refreshed = false
      registry.refresh(function()
        refreshed = true
      end)
      vim.wait(60000, function()
        return refreshed
      end, 100)
      log_line("MasonToolsInstallSync registry_refreshed=" .. tostring(refreshed))

      local tools = filtered_tools(false)
      if #tools == 0 then
        log_line("MasonToolsInstallSync no tools after filtering")
        return
      end
      log_line("MasonToolsInstallSync tools=" .. table.concat(tools, ", "))

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
        log_line("MasonToolsInstallSync already installed")
        return
      end

      vim.cmd("MasonInstall --sync " .. table.concat(to_install, " "))
      log_line("MasonToolsInstallSync installed=" .. table.concat(to_install, ", "))
    end, {})

    refresh_registry()

    require("mason-tool-installer").setup({
      ensure_installed = filtered_tools(false),
      run_on_start = true,
      start_delay = 2000,
    })
  end,
}
