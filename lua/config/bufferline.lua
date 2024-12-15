vim.api.nvim_create_autocommand('WinClosed', {
    callback = function(tbl)
      vim.api.nvim_command('BufferClose ' .. tbl.buf)
    end,
    group = vim.api.nvim_create_augroup('barbar_close_buf', {})
  })