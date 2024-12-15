require('barbar').setup{
    animation = true,
    insert_at_start = true,
}

vim.api.nvim_create_autocmd('WinClosed', {
    callback = function(tbl)
      if tbl.args ~= nil then
        vim.api.nvim_command('BufferClose ' .. tbl.args)
      end
    end,
    group = vim.api.nvim_create_augroup('barbar_close_buf', {})
})
