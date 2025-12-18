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
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format", "ruff_organize_imports" },
      php = { "phpcbf" },
      ruby = { "rubocop" },
      puppet = { "puppet-lint" }, -- lint-like; only runs if available
      markdown = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      typescript = { "prettier" },
      xml = { "prettier" },
      ["*"] = { "trim_whitespace" },
    },
  },
}
