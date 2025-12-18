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
    config = function()
      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")

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
        "clangd",
        "pylsp",
        "puppet",
        "ruby_lsp",
        "lemminx",
      }
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

            lspconfig[server].setup(opts)
          end,
        },
      })
    end
  },
}
