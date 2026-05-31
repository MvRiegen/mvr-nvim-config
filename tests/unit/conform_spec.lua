local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")

---@type any
local assert = assert

local function with_tooling(tooling, fn)
  local original_tooling = package.loaded["config.tooling"]
  package.loaded["config.tooling"] = tooling

  local ok, err = pcall(fn)

  package.loaded["config.tooling"] = original_tooling

  if not ok then
    error(err)
  end
end

describe("plugins.conform", function()
  it("disables format-on-save for large files", function()
    -- given
    with_tooling({
      formatter_exec = {},
      formatters_by_ft = {},
      is_executable = function(...)
        return true
      end,
    }, function()
      local original_buf_get_name = vim.api.nvim_buf_get_name
      local original_fs_stat = vim.loop.fs_stat

      vim.api.nvim_buf_get_name = function(...)
        return "large.lua"
      end
      vim.loop.fs_stat = function(...)
        return { size = 512 * 1024 + 1 }
      end

      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local result = spec.opts.format_on_save(1)

      vim.api.nvim_buf_get_name = original_buf_get_name
      vim.loop.fs_stat = original_fs_stat

      -- then
      assert.is_nil(result)
    end)
  end)

  it("keeps format-on-save enabled for small files", function()
    with_tooling({
      formatter_exec = {},
      formatters_by_ft = {},
      is_executable = function(...)
        return true
      end,
    }, function()
      -- given
      local original_buf_get_name = vim.api.nvim_buf_get_name
      local original_fs_stat = vim.loop.fs_stat

      vim.api.nvim_buf_get_name = function(...)
        return "small.lua"
      end

      vim.loop.fs_stat = function(...)
        return { size = 512 * 1024 }
      end
      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local result = spec.opts.format_on_save(1)

      vim.api.nvim_buf_get_name = original_buf_get_name
      vim.loop.fs_stat = original_fs_stat

      -- then
      assert.are.same({ timeout_ms = 2000, lsp_fallback = true }, result)
    end)
  end)

  it("keeps format-on-save enabled when file stats are missing", function()
    with_tooling({
      formatter_exec = {},
      formatters_by_ft = {},
      is_executable = function(...)
        return true
      end,
    }, function()
      -- given
      local original_buf_get_name = vim.api.nvim_buf_get_name
      local original_fs_stat = vim.loop.fs_stat

      vim.api.nvim_buf_get_name = function(...)
        return "missing.lua"
      end
      vim.loop.fs_stat = function(...)
        return nil
      end
      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local result = spec.opts.format_on_save(1)

      vim.api.nvim_buf_get_name = original_buf_get_name
      vim.loop.fs_stat = original_fs_stat

      -- then
      assert.are.same({ timeout_ms = 2000, lsp_fallback = true }, result)
    end)
  end)

  it("marks formatter condition true when executable is available", function()
    -- given
    local checked = {}

    with_tooling({
      formatter_exec = {
        stylua = "stylua",
      },
      formatters_by_ft = {
        lua = { "stylua" },
      },
      is_executable = function(cmd)
        checked[#checked + 1] = cmd
        return cmd == "stylua"
      end,
    }, function()
      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local stylua_available = spec.opts.formatters.stylua.condition()

      -- then
      assert.is_true(stylua_available)
      assert.are.same({ "stylua" }, checked)
    end)
  end)

  it("marks formatter condition false when executable is unavailable", function()
    -- given
    local checked = {}

    with_tooling({
      formatter_exec = {
        ruff_format = "ruff",
      },
      formatters_by_ft = {},
      is_executable = function(cmd)
        checked[#checked + 1] = cmd
        return false
      end,
    }, function()
      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local ruff_available = spec.opts.formatters.ruff_format.condition()

      -- then
      assert.is_false(ruff_available)
      assert.are.same({ "ruff" }, checked)
    end)
  end)

  it("reuses formatter mappings from config.tooling", function()
    -- given
    local formatters_by_ft = {
      lua = { "stylua" },
    }

    with_tooling({
      formatter_exec = {},
      formatters_by_ft = formatters_by_ft,
      is_executable = function(...)
        return true
      end,
    }, function()
      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local configured = spec.opts.formatters_by_ft

      -- then
      assert.are.same(formatters_by_ft, configured)
    end)
  end)

  it("configures xmllint formatting explicitly", function()
    -- given
    with_tooling({
      formatter_exec = {},
      formatters_by_ft = {},
      is_executable = function(cmd)
        return cmd == "xmllint"
      end,
    }, function()
      local spec = dofile(root .. "/lua/plugins/conform.lua")

      -- when
      local xmllint = spec.opts.formatters.xmllint
      local available = xmllint.condition()

      -- then
      assert.are.equal("xmllint", xmllint.command)
      assert.are.same({ "--format", "-" }, xmllint.args)
      assert.is_true(xmllint.stdin)
      assert.is_true(available)
    end)
  end)
end)
