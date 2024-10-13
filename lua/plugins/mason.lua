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
        ensure_installed = { "lua_ls", "clangd", "pylsp"},
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({})
      lspconfig.clangd.setup({})
      -- Keybinds
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {}) -- Dokumentation hervorufen
      vim.keymap.set({'n','v'}, '<leader>ka', vim.lsp.buf.code_action, {}) -- Code Action aufrufen
    end
  }
}