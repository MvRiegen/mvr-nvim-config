local opts = {
  ensure_installed = {
    'c',
    'lua',
    'vim',
    'vimdoc',
    'query',
    'php',
    'puppet',
    'markdown',
    'markdown_inline',
    'json',
    'yaml',
    'javascript',
    'typescript',
    'xml',
    'html',
    'make',
    'dockerfile',
    'groovy',
  },
  auto_install = true,
  highlight = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
    },
  },
}

local function config()
  require('nvim-treesitter.configs').setup(opts)
end

return {
  'nvim-treesitter/nvim-treesitter',
  config = config,
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    {
      'nvim-treesitter/nvim-treesitter-context',
      config = function()
        require("treesitter-context").setup({})
      end,
    },
  },
  build = ':TSUpdate',
}
