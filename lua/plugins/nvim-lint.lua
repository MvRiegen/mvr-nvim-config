local tooling = require("config.tooling")

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")

    local function linter_available(name)
      local linter = lint.linters[name]
      if not linter then
        return false
      end
      return tooling.is_executable(linter.cmd or name)
    end

    local linters = vim.deepcopy(tooling.linters_by_ft)
    for ft, list in pairs(linters) do
      local filtered = {}
      for _, name in ipairs(list) do
        if linter_available(name) then
          table.insert(filtered, name)
        end
      end
      linters[ft] = filtered
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
