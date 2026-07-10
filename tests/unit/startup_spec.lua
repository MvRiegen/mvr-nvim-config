local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")
local startup = dofile(root .. "/lua/config/startup.lua")

---@type any
local assert = assert

local function reset_startup_state()
  vim.g.no_session_autoload = nil
  vim.env.NVIM_NO_SESSION = nil
end

describe("config.startup", function()
  before_each(reset_startup_state)
  after_each(reset_startup_state)

  it("defaults to normal startup", function()
    assert.is_false(startup.clean_session_requested())
  end)

  it("accepts a global flag", function()
    vim.g.no_session_autoload = 1

    assert.is_true(startup.clean_session_requested())
  end)

  it("accepts an environment flag", function()
    vim.env.NVIM_NO_SESSION = "1"

    assert.is_true(startup.clean_session_requested())
  end)

  it("ignores unrelated values", function()
    vim.g.no_session_autoload = 0
    vim.env.NVIM_NO_SESSION = "0"

    assert.is_false(startup.clean_session_requested())
  end)
end)
