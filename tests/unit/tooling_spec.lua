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

local function load_tooling_with_env(env)
  local original_has = vim.fn.has
  local original_executable = vim.fn.executable
  local original_os_uname = vim.uv.os_uname

  vim.fn.has = function(feature)
    return env.has and env.has[feature] or 0
  end

  vim.fn.executable = function(cmd)
    return env.executable and env.executable[cmd] or 0
  end

  vim.uv.os_uname = function()
    return { machine = env.machine }
  end

  local ok, loaded = pcall(dofile, root .. "/lua/config/tooling.lua")

  vim.fn.has = original_has
  vim.fn.executable = original_executable
  vim.uv.os_uname = original_os_uname

  assert.is_true(ok)
  return loaded
end

local function with_vim_fn_stubs(stubs, fn)
  local original_has = vim.fn.has
  local original_executable = vim.fn.executable

  if stubs.has then
    vim.fn.has = stubs.has
  end
  if stubs.executable then
    vim.fn.executable = stubs.executable
  end

  local ok, err = pcall(fn)

  vim.fn.has = original_has
  vim.fn.executable = original_executable

  if not ok then
    error(err)
  end
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

  it("checks executables after unwrapping command tables", function()
    with_vim_fn_stubs({
      executable = function(cmd)
        return cmd == "ruff" and 1 or 0
      end,
    }, function()
      assert.is_true(tooling.is_executable({ "ruff", "format" }))
      assert.is_false(tooling.is_executable("stylua"))
      assert.is_true(tooling.is_executable(nil))
      assert.is_true(tooling.is_executable({}))
    end)
  end)

  it("detects windows and MSVC cl through vim.fn", function()
    with_vim_fn_stubs({
      has = function(feature)
        return feature == "win64" and 1 or 0
      end,
      executable = function(cmd)
        return cmd == "cl" and 1 or 0
      end,
    }, function()
      assert.is_true(tooling.is_windows())
      assert.is_true(tooling.has_msvc_cl())
    end)
  end)

  it("initializes mason tools from the detected environment", function()
    local loaded = load_tooling_with_env({
      machine = "aarch64",
      has = { win32 = 1 },
      executable = { cl = 0 },
    })

    assert.is_false(contains(loaded.mason_tools, "checkmake"))
    assert.is_false(contains(loaded.mason_tools, "luacheck"))
    assert.is_true(contains(loaded.mason_tools, "stylua"))
  end)
end)
