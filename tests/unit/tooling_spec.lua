local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")

local tooling = dofile(root .. "/lua/config/tooling.lua")

local tests = {}

local function add(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

local function assert_contains(list, value)
  assert(contains(list, value), ("expected list to contain %s"):format(value))
end

local function assert_not_contains(list, value)
  assert(not contains(list, value), ("expected list not to contain %s"):format(value))
end

local function assert_list_eq(actual, expected)
  assert(vim.deep_equal(actual, expected), ("expected %s, got %s"):format(vim.inspect(expected), vim.inspect(actual)))
end

add("detects arm64 machine names", function()
  assert(tooling.is_arm64_machine("aarch64"))
  assert(tooling.is_arm64_machine("arm64"))
  assert(tooling.is_arm64_machine("ARM64"))
end)

add("rejects non-arm64 machine names", function()
  assert(not tooling.is_arm64_machine("x86_64"))
  assert(not tooling.is_arm64_machine("amd64"))
  assert(not tooling.is_arm64_machine(nil))
end)

add("keeps default mason tools unchanged while filtering arm64 tools", function()
  local tools = { "luacheck", "checkmake", "stylua" }
  local filtered = tooling.filter_mason_tools(tools, { is_arm64 = true, is_windows = false, has_msvc_cl = true })

  assert_list_eq(tools, { "luacheck", "checkmake", "stylua" })
  assert_list_eq(filtered, { "luacheck", "stylua" })
end)

add("removes luacheck on windows without MSVC cl", function()
  local filtered = tooling.filter_mason_tools({ "luacheck", "checkmake", "stylua" }, {
    is_arm64 = false,
    is_windows = true,
    has_msvc_cl = false,
  })

  assert_not_contains(filtered, "luacheck")
  assert_contains(filtered, "checkmake")
  assert_contains(filtered, "stylua")
end)

add("removes architecture and windows-specific unsupported tools together", function()
  local filtered = tooling.filter_mason_tools({ "luacheck", "checkmake", "stylua" }, {
    is_arm64 = true,
    is_windows = true,
    has_msvc_cl = false,
  })

  assert_list_eq(filtered, { "stylua" })
end)

add("keeps luacheck on windows when MSVC cl is available", function()
  local filtered = tooling.filter_mason_tools({ "luacheck", "stylua" }, {
    is_arm64 = false,
    is_windows = true,
    has_msvc_cl = true,
  })

  assert_list_eq(filtered, { "luacheck", "stylua" })
end)

add("unwraps command table before executable checks", function()
  assert(tooling.unwrap_cmd("stylua") == "stylua")
  assert(tooling.unwrap_cmd({ "ruff", "format" }) == "ruff")
  assert(tooling.unwrap_cmd({}) == nil)
end)

local failures = {}

for _, test in ipairs(tests) do
  local ok, err = pcall(test.fn)
  if ok then
    print("ok - " .. test.name)
  else
    failures[#failures + 1] = ("not ok - %s\n%s"):format(test.name, err)
  end
end

if #failures > 0 then
  print(table.concat(failures, "\n"))
  error(("%d unit test(s) failed"):format(#failures))
end

print(("%d unit test(s) passed"):format(#tests))
