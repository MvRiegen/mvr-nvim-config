local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")
local tooling = dofile(root .. "/lua/config/tooling.lua")

---@type any
local assert = assert

local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

describe("config.tooling", function()
  it("detects arm64 machine names", function()
    assert.is_true(tooling.is_arm64_machine("aarch64"))
    assert.is_true(tooling.is_arm64_machine("arm64"))
    assert.is_true(tooling.is_arm64_machine("ARM64"))
  end)

  it("rejects non-arm64 machine names", function()
    assert.is_false(tooling.is_arm64_machine("x86_64"))
    assert.is_false(tooling.is_arm64_machine("amd64"))
    assert.is_false(tooling.is_arm64_machine(nil))
  end)

  it("keeps default mason tools unchanged while filtering arm64 tools", function()
    local tools = { "luacheck", "checkmake", "stylua" }
    local filtered = tooling.filter_mason_tools(tools, { is_arm64 = true, is_windows = false, has_msvc_cl = true })

    assert.are.same({ "luacheck", "checkmake", "stylua" }, tools)
    assert.are.same({ "luacheck", "stylua" }, filtered)
  end)

  it("removes luacheck on windows without MSVC cl", function()
    local filtered = tooling.filter_mason_tools({ "luacheck", "checkmake", "stylua" }, {
      is_arm64 = false,
      is_windows = true,
      has_msvc_cl = false,
    })

    assert.is_false(contains(filtered, "luacheck"))
    assert.is_true(contains(filtered, "checkmake"))
    assert.is_true(contains(filtered, "stylua"))
  end)

  it("removes architecture and windows-specific unsupported tools together", function()
    local filtered = tooling.filter_mason_tools({ "luacheck", "checkmake", "stylua" }, {
      is_arm64 = true,
      is_windows = true,
      has_msvc_cl = false,
    })

    assert.are.same({ "stylua" }, filtered)
  end)

  it("keeps luacheck on windows when MSVC cl is available", function()
    local filtered = tooling.filter_mason_tools({ "luacheck", "stylua" }, {
      is_arm64 = false,
      is_windows = true,
      has_msvc_cl = true,
    })

    assert.are.same({ "luacheck", "stylua" }, filtered)
  end)

  it("unwraps command table before executable checks", function()
    assert.are.equal("stylua", tooling.unwrap_cmd("stylua"))
    assert.are.equal("ruff", tooling.unwrap_cmd({ "ruff", "format" }))
    assert.is_nil(tooling.unwrap_cmd({}))
  end)
end)
