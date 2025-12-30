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
    event = "BufReadPre",
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
    dependencies = { "neovim/nvim-lspconfig" },
    event = "BufReadPre",
    config = function()
      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")
      local uname = (vim.uv or vim.loop).os_uname()
      local is_aarch64 = uname and uname.machine == "aarch64"
      local lemminx_jar = vim.fn.expand("~/.local/share/lemminx/lemminx.jar")
      local lemminx_available = vim.fn.filereadable(lemminx_jar) == 1
      local clangd_link = vim.fn.expand("~/.local/share/clangd/bin/clangd")
      local clangd_cmd
      if vim.fn.executable(clangd_link) == 1 then
        clangd_cmd = clangd_link
      elseif vim.fn.executable("clangd-16") == 1 then
        clangd_cmd = vim.fn.exepath("clangd-16")
      elseif vim.fn.executable("clangd") == 1 then
        clangd_cmd = vim.fn.exepath("clangd")
      end
      local clangd_available = clangd_cmd ~= nil

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end
      local function on_attach(_, bufnr)
        local ok, navic = pcall(require, "nvim-navic")
        if ok then
          navic.attach(_, bufnr)
        end

        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map('n', 'K', vim.lsp.buf.hover, "LSP hover")
        map({ 'n', 'v' }, '<leader>ka', vim.lsp.buf.code_action, "Code action")
        map('n', 'gd', vim.lsp.buf.definition, "Goto definition")
        map('n', 'gD', vim.lsp.buf.declaration, "Goto declaration")
        map('n', 'gi', vim.lsp.buf.implementation, "Goto implementation")
        map('n', 'gr', vim.lsp.buf.references, "Goto references")
        map('n', 'gl', vim.diagnostic.open_float, "Line diagnostics")
        map('n', '[d', vim.diagnostic.goto_prev, "Prev diagnostic")
        map('n', ']d', vim.diagnostic.goto_next, "Next diagnostic")
      end

      local servers = {
        "lua_ls",
        "pylsp",
        "puppet",
        "ruby_lsp",
      }
      if not is_aarch64 then
        table.insert(servers, "clangd")
        table.insert(servers, "lemminx")
      end
      if vim.fn.executable("npm") == 1 then
        vim.list_extend(servers, { "jsonls", "yamlls", "ts_ls", "html" })
      end

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

            lspconfig[server].setup(opts)
          end,
        },
      })

      if is_aarch64 and lemminx_available then
        lspconfig.lemminx.setup({
          cmd = { "java", "-jar", lemminx_jar },
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end
      if is_aarch64 and clangd_available then
        lspconfig.clangd.setup({
          cmd = { clangd_cmd },
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end
    end
  },
}
