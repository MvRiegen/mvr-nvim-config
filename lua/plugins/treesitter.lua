local ensure_installed = {
  "c",
  "lua",
  "vim",
  "vimdoc",
  "query",
  "php",
  "puppet",
  "markdown",
  "markdown_inline",
  "json",
  "yaml",
  "javascript",
  "typescript",
  "xml",
  "html",
  "make",
  "dockerfile",
  "groovy",
}

local function config()
  local ts = require("nvim-treesitter")
  -- Checkouts from the old master branch lack the new API until :Lazy sync ran.
  if not ts.install then
    vim.notify("nvim-treesitter is still on the old master branch, run :Lazy sync", vim.log.levels.WARN)
    return
  end
  ts.install(ensure_installed)

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("mvr_treesitter", { clear = true }),
    callback = function(args)
      local lang = vim.treesitter.language.get_lang(args.match)
      if not lang then
        return
      end

      if vim.treesitter.language.add(lang) then
        vim.treesitter.start(args.buf, lang)
      elseif vim.tbl_contains(ts.get_available(), lang) then
        -- Replacement for the old auto_install: highlighting starts on the next open.
        ts.install(lang)
      end
    end,
  })
end

local function textobjects_config()
  local textobjects = require("nvim-treesitter-textobjects")
  if not textobjects.setup then
    return
  end
  textobjects.setup({
    select = { lookahead = true },
    move = { set_jumps = true },
  })

  local select = require("nvim-treesitter-textobjects.select")
  local move = require("nvim-treesitter-textobjects.move")

  for keys, capture in pairs({
    ["af"] = "@function.outer",
    ["if"] = "@function.inner",
    ["ac"] = "@class.outer",
    ["ic"] = "@class.inner",
  }) do
    vim.keymap.set({ "x", "o" }, keys, function()
      select.select_textobject(capture, "textobjects")
    end)
  end

  for keys, mapping in pairs({
    ["]m"] = { move.goto_next_start, "@function.outer" },
    ["]]"] = { move.goto_next_start, "@class.outer" },
    ["[m"] = { move.goto_previous_start, "@function.outer" },
    ["[["] = { move.goto_previous_start, "@class.outer" },
  }) do
    vim.keymap.set({ "n", "x", "o" }, keys, function()
      mapping[1](mapping[2], "textobjects")
    end)
  end
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  config = config,
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = "main",
      config = textobjects_config,
    },
    {
      "nvim-treesitter/nvim-treesitter-context",
      config = function()
        require("treesitter-context").setup({})
      end,
    },
  },
  build = ":TSUpdate",
}
