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

  rawset(vim.uv, "os_uname", function()
    return { machine = env.machine }
  end)

  local ok, loaded = pcall(dofile, root .. "/lua/config/tooling.lua")

  vim.fn.has = original_has
  vim.fn.executable = original_executable
  rawset(vim.uv, "os_uname", original_os_uname)

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
    -- given
    local machine_names = { "aarch64", "arm64", "ARM64" }

    -- when
    local results = vim.tbl_map(tooling.is_arm64_machine, machine_names)

    -- then
    assert.are.same({ true, true, true }, results)
  end)

  it("rejects non-arm64 machine names", function()
    -- given
    local machine_names = { "x86_64", "amd64", nil }

    -- when
    local results = {
      tooling.is_arm64_machine(machine_names[1]),
      tooling.is_arm64_machine(machine_names[2]),
      tooling.is_arm64_machine(machine_names[3]),
    }

    -- then
    assert.are.same({ false, false, false }, results)
  end)

  it("does not mutate mason tools while filtering", function()
    -- given
    local tools = { "luacheck", "checkmake", "stylua" }

    -- when
    tooling.filter_mason_tools(tools, { is_arm64 = true, is_windows = false, has_msvc_cl = true })

    -- then
    assert.are.same({ "luacheck", "checkmake", "stylua" }, tools)
  end)

  it("removes checkmake on arm64", function()
    -- given
    local tools = { "luacheck", "checkmake", "stylua" }

    -- when
    local filtered = tooling.filter_mason_tools(tools, { is_arm64 = true, is_windows = false, has_msvc_cl = true })

    -- then
    assert.are.same({ "luacheck", "stylua" }, filtered)
  end)

  it("removes luacheck on windows without MSVC cl", function()
    -- given
    local tools = { "luacheck", "checkmake", "stylua" }

    -- when
    local filtered = tooling.filter_mason_tools(tools, {
      is_arm64 = false,
      is_windows = true,
      has_msvc_cl = false,
    })

    -- then
    assert.is_false(contains(filtered, "luacheck"))
    assert.is_true(contains(filtered, "checkmake"))
    assert.is_true(contains(filtered, "stylua"))
  end)

  it("removes architecture and windows-specific unsupported tools together", function()
    -- given
    local tools = { "luacheck", "checkmake", "stylua" }

    -- when
    local filtered = tooling.filter_mason_tools(tools, {
      is_arm64 = true,
      is_windows = true,
      has_msvc_cl = false,
    })

    -- then
    assert.are.same({ "stylua" }, filtered)
  end)

  it("keeps luacheck on windows when MSVC cl is available", function()
    -- given
    local tools = { "luacheck", "stylua" }

    -- when
    local filtered = tooling.filter_mason_tools(tools, {
      is_arm64 = false,
      is_windows = true,
      has_msvc_cl = true,
    })

    -- then
    assert.are.same({ "luacheck", "stylua" }, filtered)
  end)

  it("keeps string commands unchanged when unwrapping", function()
    -- given
    local cmd = "stylua"

    -- when
    local unwrapped = tooling.unwrap_cmd(cmd)

    -- then
    assert.are.equal("stylua", unwrapped)
  end)

  it("unwraps command tables to their first item", function()
    -- given
    local cmd = { "ruff", "format" }

    -- when
    local unwrapped = tooling.unwrap_cmd(cmd)

    -- then
    assert.are.equal("ruff", unwrapped)
  end)

  it("unwraps empty command tables to nil", function()
    -- given
    local cmd = {}

    -- when
    local unwrapped = tooling.unwrap_cmd(cmd)

    -- then
    assert.is_nil(unwrapped)
  end)

  it("checks executable command tables by their first item", function()
    with_vim_fn_stubs({
      executable = function(cmd)
        return cmd == "ruff" and 1 or 0
      end,
    }, function()
      -- given
      local cmd = { "ruff", "format" }

      -- when
      local executable = tooling.is_executable(cmd)

      -- then
      assert.is_true(executable)
    end)
  end)

  it("rejects unavailable executable strings", function()
    with_vim_fn_stubs({
      executable = function(...)
        return 0
      end,
    }, function()
      -- given
      local cmd = "stylua"

      -- when
      local executable = tooling.is_executable(cmd)

      -- then
      assert.is_false(executable)
    end)
  end)

  it("accepts non-string executable values", function()
    -- given
    local commands = { nil, {} }

    -- when
    local results = {
      tooling.is_executable(commands[1]),
      tooling.is_executable(commands[2]),
    }

    -- then
    assert.are.same({ true, true }, results)
  end)

  it("detects windows through vim.fn", function()
    with_vim_fn_stubs({
      has = function(feature)
        return feature == "win64" and 1 or 0
      end,
    }, function()
      -- given
      local expected_windows = true

      -- when
      local is_windows = tooling.is_windows()

      -- then
      assert.are.equal(expected_windows, is_windows)
    end)
  end)

  it("detects MSVC cl through vim.fn", function()
    with_vim_fn_stubs({
      executable = function(cmd)
        return cmd == "cl" and 1 or 0
      end,
    }, function()
      -- given
      local expected_cl = true

      -- when
      local has_cl = tooling.has_msvc_cl()

      -- then
      assert.are.equal(expected_cl, has_cl)
    end)
  end)

  it("initializes mason tools from the detected environment", function()
    -- given
    local env = {
      machine = "aarch64",
      has = { win32 = 1 },
      executable = { cl = 0 },
    }

    -- when
    local loaded = load_tooling_with_env(env)

    -- then
    assert.is_false(contains(loaded.mason_tools, "checkmake"))
    assert.is_false(contains(loaded.mason_tools, "luacheck"))
    assert.is_true(contains(loaded.mason_tools, "stylua"))
  end)
end)
