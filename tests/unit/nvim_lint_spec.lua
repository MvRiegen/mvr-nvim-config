local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")

---@type any
local assert = assert

local function contains(list, value)
  for _, item in ipairs(list) do
    if vim.deep_equal(item, value) then
      return true
    end
  end
  return false
end

local function with_modules(modules, fn)
  local original_loaded = {}
  local original_preload = {}

  for name, module in pairs(modules) do
    original_loaded[name] = package.loaded[name]
    original_preload[name] = package.preload[name]
    package.loaded[name] = nil
    package.preload[name] = function(...)
      return module
    end
  end

  local ok, err = pcall(fn)

  for name in pairs(modules) do
    package.loaded[name] = original_loaded[name]
    package.preload[name] = original_preload[name]
  end

  if not ok then
    error(err)
  end
end

describe("plugins.nvim-lint", function()
  it("filters configured linters to available executables", function()
    -- given
    local lint = {
      linters = {
        luacheck = { cmd = "luacheck" },
        ruff = { cmd = { "ruff", "check" } },
        shellcheck = {},
      },
      linters_by_ft = {},
      try_lint = function(...) end,
    }
    local checked = {}

    with_modules({
      ["config.tooling"] = {
        linters_by_ft = {
          lua = { "luacheck", "missing" },
          python = { "ruff" },
          sh = { "shellcheck" },
        },
        is_executable = function(cmd)
          checked[#checked + 1] = cmd
          return cmd == "luacheck" or type(cmd) == "table"
        end,
      },
      lint = lint,
    }, function()
      local spec = dofile(root .. "/lua/plugins/nvim-lint.lua")

      -- when
      spec.config()

      -- then
      assert.are.same({ lua = { "luacheck" }, python = { "ruff" }, sh = {} }, lint.linters_by_ft)
      assert.are.equal(3, #checked)
      assert.is_true(contains(checked, "luacheck"))
      assert.is_true(contains(checked, { "ruff", "check" }))
      assert.is_true(contains(checked, "shellcheck"))
    end)
  end)

  it("registers linting for buffer enter and write", function()
    -- given
    local lint = {
      linters = {},
      linters_by_ft = {},
      try_lint = function(...) end,
    }
    local autocmd
    local original_create_autocmd = vim.api.nvim_create_autocmd

    with_modules({
      ["config.tooling"] = {
        linters_by_ft = {},
        is_executable = function(...)
          return true
        end,
      },
      lint = lint,
    }, function()
      vim.api.nvim_create_autocmd = function(events, opts, ...)
        autocmd = { events = events, opts = opts }
      end

      local spec = dofile(root .. "/lua/plugins/nvim-lint.lua")

      -- when
      spec.config()

      vim.api.nvim_create_autocmd = original_create_autocmd

      -- then
      assert.are.same({ "BufEnter", "BufWritePost" }, autocmd.events)
      assert.are.equal("function", type(autocmd.opts.callback))
    end)
  end)
end)
