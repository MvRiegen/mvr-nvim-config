local tooling = require("config.tooling")

local formatters = {}
for name, cmd in pairs(tooling.formatter_exec) do
  formatters[name] = {
    condition = function()
      return tooling.is_executable(cmd)
    end,
  }
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  opts = {
    notify_on_error = true,
    format_on_save = function(bufnr)
      -- disable for large files
      local max_size = 512 * 1024
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
      if ok and stats and stats.size > max_size then
        return nil
      end
      return { timeout_ms = 2000, lsp_fallback = true }
    end,
    formatters = formatters,
    formatters_by_ft = tooling.formatters_by_ft,
  },
}
