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
    formatters = {
      stylua = { condition = function() return vim.fn.executable("stylua") == 1 end },
      ruff_format = { condition = function() return vim.fn.executable("ruff") == 1 end },
      ruff_organize_imports = { condition = function() return vim.fn.executable("ruff") == 1 end },
      phpcbf = { condition = function() return vim.fn.executable("phpcbf") == 1 end },
      rubocop = { condition = function() return vim.fn.executable("rubocop") == 1 end },
      prettier = { condition = function() return vim.fn.executable("prettier") == 1 end },
      ["puppet-lint"] = { condition = function() return vim.fn.executable("puppet-lint") == 1 end },
    },
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
      html = { "prettier" },
      ["*"] = { "trim_whitespace" },
    },
  },
}
