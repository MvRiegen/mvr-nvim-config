return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local function is_executable(cmd)
      if type(cmd) == "table" then
        cmd = cmd[1]
      end
      if type(cmd) ~= "string" then
        return true
      end
      return vim.fn.executable(cmd) == 1
    end

    local function linter_available(name)
      local linter = lint.linters[name]
      if not linter then
        return false
      end
      return is_executable(linter.cmd or name)
    end

    local function filter_linters(list)
      local out = {}
      for _, name in ipairs(list) do
        if linter_available(name) then
          table.insert(out, name)
        end
      end
      return out
    end

    local linters = {
      lua = { "luacheck" },
      python = { "ruff" },
      php = { "phpcs" },
      markdown = { "markdownlint" },
      puppet = { "puppet-lint" },
      ruby = { "rubocop" },
      yaml = { "yamllint" },
      json = { "jsonlint" },
      typescript = { "eslint_d" },
    }
    if lint.linters.xmllint then
      linters.xml = { "xmllint" }
    end
    if lint.linters.htmlhint then
      linters.html = { "htmlhint" }
    end
    for ft, list in pairs(linters) do
      linters[ft] = filter_linters(list)
    end
    lint.linters_by_ft = linters

    local function try_lint()
      lint.try_lint()
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
      callback = try_lint,
    })
  end,
}
