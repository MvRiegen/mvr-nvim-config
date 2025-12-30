local lua_ls_setup = {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
}

-- Standardkonfiguration mit Icons setzen
return {
  {
    "williamboman/mason.nvim",
    event = "VimEnter",
    config = function()
      require("mason").setup {
        max_concurrent_installers = 1,
        ui = {
          icons = {
            package_installed = "*",
            package_pending = "~",
            package_uninstalled = " ",
          },
        },
      }
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    event = "VimEnter",
    cmd = { "MasonLspInstallSync" },
    config = function()
      local lsp = vim.lsp
      local mason_lspconfig = require("mason-lspconfig")
      local uname = (vim.uv or vim.loop).os_uname()
      local is_aarch64 = uname and uname.machine == "aarch64"
      local lemminx_jar = vim.fn.expand("~/.local/share/lemminx/lemminx.jar")
      local lemminx_available = vim.fn.filereadable(lemminx_jar) == 1
      local clangd_link = vim.fn.expand("~/.local/share/clangd/bin/clangd")
      local function resolve_clangd_cmd()
        if vim.fn.executable(clangd_link) == 1 then
          return clangd_link
        end
        if vim.fn.executable("clangd-16") == 1 then
          return vim.fn.exepath("clangd-16")
        end
        if vim.fn.executable("clangd") == 1 then
          return vim.fn.exepath("clangd")
        end
      end
      local clangd_cmd = resolve_clangd_cmd()
      local clangd_available = clangd_cmd ~= nil

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end
      local function on_attach(client, bufnr)
        local ok, navic = pcall(require, "nvim-navic")
        if ok then
          navic.attach(client, bufnr)
        end

        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map('n', 'K', vim.lsp.buf.hover, "LSP hover")
        map({ 'n', 'v' }, '<leader>ka', vim.lsp.buf.code_action, "Code action")
        map('n', '<leader>kr', vim.lsp.buf.rename, "Rename symbol")
        map('n', 'gd', vim.lsp.buf.definition, "Goto definition")
        map('n', 'gD', vim.lsp.buf.declaration, "Goto declaration")
        map('n', 'gi', vim.lsp.buf.implementation, "Goto implementation")
        map('n', 'gr', vim.lsp.buf.references, "Goto references")
        map('n', 'gl', vim.diagnostic.open_float, "Line diagnostics")
        map('n', '[d', vim.diagnostic.goto_prev, "Prev diagnostic")
        map('n', ']d', vim.diagnostic.goto_next, "Next diagnostic")

        if vim.lsp.inlay_hint and client.supports_method("textDocument/inlayHint") then
          pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
        end

        if vim.lsp.codelens and client.supports_method("textDocument/codeLens") then
          local group = vim.api.nvim_create_augroup("LspCodeLens", { clear = false })
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            group = group,
            buffer = bufnr,
            callback = function()
              pcall(vim.lsp.codelens.refresh)
            end,
          })
          pcall(vim.lsp.codelens.refresh)
        end
      end

      local servers = {
        "lua_ls",
        "pyright",
        "puppet",
        "ruby_lsp",
      }
      if not is_aarch64 then
        table.insert(servers, "clangd")
        table.insert(servers, "lemminx")
      end
      if vim.fn.executable("npm") == 1 then
        vim.list_extend(servers, { "jsonls", "yamlls", "ts_ls", "html", "bashls" })
      end

      local function mason_lsp_packages()
        local ok_mappings, mappings = pcall(require, "mason-lspconfig.mappings.server")
        if not ok_mappings then
          return nil, "missing mappings"
        end
        local out = {}
        local seen = {}
        for _, server in ipairs(servers) do
          local pkg = mappings.lspconfig_to_mason[server]
          if pkg and not seen[pkg] then
            seen[pkg] = true
            table.insert(out, pkg)
          end
        end
        return out, nil
      end

      local function log_line(msg)
        local path = vim.fn.stdpath("state") .. "/mason-sync.log"
        vim.fn.writefile({ os.date("%F %T") .. " " .. msg }, path, "a")
      end

      log_line("mason-lspconfig loaded; data_dir=" .. vim.fn.stdpath("data"))

      vim.api.nvim_create_user_command("MasonLspInstallSync", function()
        log_line("MasonLspInstallSync start")
        log_line("MasonLspInstallSync npm=" .. tostring(vim.fn.executable("npm") == 1))
        log_line("MasonLspInstallSync servers=" .. table.concat(servers, ", "))

        local packages, err = mason_lsp_packages()
        if not packages or #packages == 0 then
          log_line("MasonLspInstallSync no packages (" .. (err or "empty list") .. ")")
          return
        end
        log_line("MasonLspInstallSync packages=" .. table.concat(packages, ", "))

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

        for _, name in ipairs(packages) do
          local ok_pkg, pkg = pcall(registry.get_package, name)
          if ok_pkg then
            if not pkg:is_installed() then
              table.insert(to_install, name)
            elseif type(pkg.check_new_version) == "function" then
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

        if pending == 0 then
          finalize()
        else
          vim.wait(60000, function()
            return done
          end, 100)
        end

        if #to_install == 0 then
          log_line("MasonLspInstallSync already installed")
          return
        end

        vim.cmd("MasonInstall --sync " .. table.concat(to_install, " "))
        log_line("MasonLspInstallSync installed=" .. table.concat(to_install, ", "))
      end, {})

      mason_lspconfig.setup({
        -- Installation der LSPs für Lua, C und Python
        ensure_installed = servers,
        handlers = {
          function(server)
            local opts = {
              capabilities = capabilities,
              on_attach = on_attach,
            }

            if server == "lua_ls" then
              opts = vim.tbl_deep_extend("force", lua_ls_setup, opts)
            end
            if server == "clangd" then
              if clangd_available then
                opts.cmd = { clangd_cmd }
              elseif is_aarch64 then
                return
              end
            end
            if server == "lemminx" then
              if lemminx_available then
                opts.cmd = { "java", "-jar", lemminx_jar }
              elseif is_aarch64 then
                return
              end
            end

            lsp.config(server, opts)
            lsp.enable(server)
          end,
        },
      })

      local function refresh_platform_ls()
        if not is_aarch64 then
          return
        end

        local lemminx_ready = vim.fn.filereadable(lemminx_jar) == 1
        local refreshed_clangd_cmd = resolve_clangd_cmd()

        if lemminx_ready then
          lsp.config("lemminx", {
            cmd = { "java", "-jar", lemminx_jar },
            capabilities = capabilities,
            on_attach = on_attach,
          })
          lsp.enable("lemminx")
        end
        if refreshed_clangd_cmd then
          lsp.config("clangd", {
            cmd = { refreshed_clangd_cmd },
            capabilities = capabilities,
            on_attach = on_attach,
          })
          lsp.enable("clangd")
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "PlatformToolsUpdated",
        callback = refresh_platform_ls,
      })
      refresh_platform_ls()
    end
  },
}
