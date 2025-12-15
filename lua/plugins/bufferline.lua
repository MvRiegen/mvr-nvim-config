local function close_and_focus(bufnr)
  -- do not close NvimTree, just leave
  if vim.bo[bufnr].filetype == "NvimTree" then
    return
  end

  -- switch to alternate listed buffer if available and not tree
  local prev = vim.fn.bufnr("#")
  if prev > 0 and vim.fn.buflisted(prev) == 1 and vim.bo[prev].filetype ~= "NvimTree" then
    vim.cmd("buffer " .. prev)
  end

  pcall(vim.cmd, "bdelete " .. bufnr)

  -- if we landed in the tree, jump to the first other listed buffer
  if vim.bo.filetype == "NvimTree" then
    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if vim.api.nvim_buf_is_valid(buf.bufnr) and vim.bo[buf.bufnr].filetype ~= "NvimTree" then
        vim.cmd("buffer " .. buf.bufnr)
        break
      end
    end
  end
end

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
      offsets = { { filetype = "NvimTree", text = "File Explorer", separator = true } },
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
