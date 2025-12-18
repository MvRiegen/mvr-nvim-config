local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed,
    }
  end
end

local function navic_location()
  local ok, navic = pcall(require, "nvim-navic")
  if not ok then
    return ""
  end
  return navic.get_location()
end

local function tooling_status()
  local ft = vim.bo.filetype
  if ft == "" then
    return ""
  end

  local parts = {}

  local ok_conform, conform = pcall(require, "conform")
  if ok_conform and conform.list_formatters then
    local fmts = {}
    for _, fmt in ipairs(conform.list_formatters(0)) do
      local name = fmt.name
      if name and fmt.available ~= false and name ~= "trim_whitespace" then
        table.insert(fmts, name)
      end
    end
    if #fmts > 0 then
      table.insert(parts, "fmt:" .. table.concat(fmts, ","))
    end
  end

  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    local linters = lint.linters_by_ft[ft] or {}
    if #linters > 0 then
      table.insert(parts, "lint:" .. table.concat(linters, ","))
    end
  end

  return table.concat(parts, " ")
end

local function line_ending()
  local ff = vim.bo.fileformat
  if ff == "dos" then
    return "CRLF"
  elseif ff == "mac" then
    return "CR"
  end
  return "LF"
end

local config = function()
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'catppuccin',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = true,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {
      'branch',
      { 'diff', source = diff_source },
      'diagnostics'
    },
    lualine_c = { navic_location },
    lualine_x = {tooling_status, 'encoding', line_ending, 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}
end

-- Lualine installieren
return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    config = config,
}
