local function pick_non_tree_target(current)
  -- Prefer alternate buffer if valid
  local alt = vim.fn.bufnr("#")
  if alt > 0 and vim.fn.buflisted(alt) == 1 and vim.bo[alt].filetype ~= "NvimTree" then
    return alt
  end

  -- Otherwise pick most recently used listed buffer (non-tree)
  local candidates = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(candidates, function(a, b)
    return (a.lastused or 0) > (b.lastused or 0)
  end)
  for _, buf in ipairs(candidates) do
    if buf.bufnr ~= current and vim.api.nvim_buf_is_valid(buf.bufnr) and vim.bo[buf.bufnr].filetype ~= "NvimTree" then
      return buf.bufnr
    end
  end
end

local function close_and_focus(bufnr, force)
  -- do not close NvimTree, just leave
  if vim.bo[bufnr].filetype == "NvimTree" then
    return
  end

  local target = pick_non_tree_target(bufnr)

  if force then
    pcall(vim.cmd, "bdelete! " .. bufnr)
  else
    pcall(vim.cmd, "bdelete " .. bufnr)
  end

  if target and vim.api.nvim_buf_is_valid(target) and vim.bo[target].filetype ~= "NvimTree" then
    vim.cmd("buffer " .. target)
  end
end

local function cleanup_empty_buffers()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs <= 1 then
    return
  end
  for _, buf in ipairs(bufs) do
    if buf.name == "" and buf.changed == 0 and buf.linecount <= 1 then
      pcall(vim.api.nvim_buf_delete, buf.bufnr, { force = true })
    end
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = cleanup_empty_buffers,
})

local function smart_bdelete(force)
  local bufnr = vim.api.nvim_get_current_buf()
  if force then
    close_and_focus(bufnr, true)
  else
    close_and_focus(bufnr)
  end
  cleanup_empty_buffers()
end

-- Replace :q / :q! to close buffer but keep layout/tree intact
vim.api.nvim_create_user_command("Bq", function(opts)
  smart_bdelete(opts.bang)
end, { bang = true })

vim.api.nvim_create_user_command("Bx", function(opts)
  local function try_write(force)
    if not vim.bo.modified then
      return true
    end
    return pcall(vim.cmd, force and "silent write!" or "silent write")
  end

  if try_write(opts.bang) then
    smart_bdelete(opts.bang)
  end
end, { bang = true })

vim.cmd([[
cnoreabbrev <expr> q  (getcmdtype() == ':' && getcmdline() == 'q')  ? 'Bq' : 'q'
cnoreabbrev <expr> q! (getcmdtype() == ':' && getcmdline() == 'q!') ? 'Bq!' : 'q!'
cnoreabbrev <expr> x  (getcmdtype() == ':' && getcmdline() == 'x')  ? 'Bx' : 'x'
cnoreabbrev <expr> x! (getcmdtype() == ':' && getcmdline() == 'x!') ? 'Bx!' : 'x!'
]])

return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      diagnostics = "nvim_lsp",
      separator_style = { "", "" },
      indicator = { style = "underline" },
      show_buffer_close_icons = true,
      close_command = close_and_focus,
      right_mouse_command = close_and_focus,
      offsets = { { filetype = "NvimTree", text = " EXPLORER", separator = true, text_align = "left" } },
      custom_filter = function(bufnr)
        -- hide NvimTree from the bufferline so its tab cannot be closed accidentally
        return vim.bo[bufnr].filetype ~= "NvimTree"
      end,
      custom_areas = {
        right = function()
          local gs = vim.b.gitsigns_status_dict
          if not gs or gs.head == "" then
            return {}
          end

          local items = {
            { text = " git:" .. gs.head .. " " },
          }
          local function add(count, prefix)
            if count and count > 0 then
              table.insert(items, { text = prefix .. count .. " " })
            end
          end
          add(gs.added, "+")
          add(gs.changed, "~")
          add(gs.removed, "-")
          return items
        end,
      },
    },
  },
  keys = {
    { "<S-l>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    { "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
    { "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>", desc = "Buffer 1" },
    { "<leader>2", "<Cmd>BufferLineGoToBuffer 2<CR>", desc = "Buffer 2" },
    { "<leader>3", "<Cmd>BufferLineGoToBuffer 3<CR>", desc = "Buffer 3" },
    { "<leader>4", "<Cmd>BufferLineGoToBuffer 4<CR>", desc = "Buffer 4" },
  },
}
