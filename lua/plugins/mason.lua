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
            package_installed = "?",
            package_pending = "?",
            package_uninstalled = "?"
          },
        },
      }
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        -- Installation der LSPs für Lua, C und Python
        ensure_installed = { "lua_ls", "clangd", "pylsp", "puppet", "ruby_lsp"},
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local config = vim.lsp.config
      config.lua_ls = vim.tbl_deep_extend("force", config.lua_ls or {}, lua_ls_setup)
      config.clangd = vim.tbl_deep_extend("force", config.clangd or {}, {})

      -- server starten
      vim.lsp.enable(config.lua_ls)
      vim.lsp.enable(config.clangd)

      -- Keybinds
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {}) -- Dokumentation hervorufen
      vim.keymap.set({'n','v'}, '<leader>ka', vim.lsp.buf.code_action, {}) -- Code Action aufrufen
    end
  }
}
