local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")

---@type any
local assert = assert

local function contains_text(items, text)
  for _, item in ipairs(items) do
    if item:find(text, 1, true) then
      return true
    end
  end
  return false
end

local function with_platform_env(env, fn)
  local original_os_uname = vim.uv.os_uname
  local original_expand = vim.fn.expand
  local original_filereadable = vim.fn.filereadable
  local original_isdirectory = vim.fn.isdirectory
  local original_mkdir = vim.fn.mkdir
  local original_executable = vim.fn.executable
  local original_exepath = vim.fn.exepath
  local original_getftype = vim.fn.getftype
  local original_create_user_command = vim.api.nvim_create_user_command
  local original_defer_fn = vim.defer_fn
  local original_notify = vim.notify
  local original_system = vim.system
  local original_platform_tools = vim.g.platform_tools

  local commands = {}
  local notifications = {}

  rawset(vim.uv, "os_uname", function()
    return { machine = env.machine }
  end)
  vim.fn.expand = env.expand or function(path)
    return path
  end
  vim.fn.filereadable = env.filereadable or function(...)
    return 0
  end
  vim.fn.isdirectory = env.isdirectory or function(...)
    return 1
  end
  vim.fn.mkdir = env.mkdir or function(...) end
  vim.fn.executable = env.executable or function(...)
    return 0
  end
  vim.fn.exepath = env.exepath or function(cmd)
    return cmd
  end
  vim.fn.getftype = env.getftype or function(...)
    return ""
  end
  vim.api.nvim_create_user_command = function(name, callback, ...)
    commands[name] = callback
  end
  vim.defer_fn = function(...) end
  vim.notify = function(message, ...)
    notifications[#notifications + 1] = message
  end
  vim.system = env.system or function(...)
    error("unexpected vim.system call")
  end
  vim.g.platform_tools = env.platform_tools

  local ok, err = pcall(fn, commands, notifications)

  rawset(vim.uv, "os_uname", original_os_uname)
  vim.fn.expand = original_expand
  vim.fn.filereadable = original_filereadable
  vim.fn.isdirectory = original_isdirectory
  vim.fn.mkdir = original_mkdir
  vim.fn.executable = original_executable
  vim.fn.exepath = original_exepath
  vim.fn.getftype = original_getftype
  vim.api.nvim_create_user_command = original_create_user_command
  vim.defer_fn = original_defer_fn
  vim.notify = original_notify
  vim.system = original_system
  vim.g.platform_tools = original_platform_tools

  if not ok then
    error(err)
  end
end

describe("plugins.platform-tools", function()
  it("skips async installation outside aarch64", function()
    -- given
    with_platform_env({ machine = "x86_64" }, function(commands, notifications)
      local spec = dofile(root .. "/lua/plugins/platform-tools.lua")
      spec.config()

      -- when
      commands.PlatformToolsInstall()

      -- then
      assert.are.same({}, notifications)
    end)
  end)

  it("skips sync installation outside aarch64", function()
    -- given
    with_platform_env({ machine = "x86_64" }, function(commands, notifications)
      local spec = dofile(root .. "/lua/plugins/platform-tools.lua")
      spec.config()

      -- when
      commands.PlatformToolsInstallSync()

      -- then
      assert.are.same({}, notifications)
    end)
  end)

  it("warns when aarch64 tools cannot be installed", function()
    -- given
    with_platform_env({ machine = "aarch64" }, function(commands, notifications)
      local spec = dofile(root .. "/lua/plugins/platform-tools.lua")
      spec.config()

      -- when
      commands.PlatformToolsInstallSync()

      -- then
      assert.is_true(contains_text(notifications, "curl/wget not found"))
      assert.is_true(contains_text(notifications, "failed to download a valid lemminx jar"))
      assert.is_true(contains_text(notifications, "clangd not found in PATH"))
    end)
  end)

  it("prefers curl over wget for synchronous downloads", function()
    -- given
    local used_cmd

    with_platform_env({
      machine = "aarch64",
      executable = function(cmd)
        return (cmd == "curl" or cmd == "wget") and 1 or 0
      end,
      system = function(cmd)
        used_cmd = cmd
        return {
          wait = function()
            return { code = 1 }
          end,
        }
      end,
    }, function(commands)
      local spec = dofile(root .. "/lua/plugins/platform-tools.lua")
      spec.config()

      -- when
      commands.PlatformToolsInstallSync()

      -- then
      assert.are.equal("curl", used_cmd[1])
      assert.is_true(contains_text(used_cmd, "-o"))
    end)
  end)
end)
