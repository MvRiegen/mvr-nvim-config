---@type any
local assert = assert

local mason_sync = require("config.mason_sync")

local function package(opts)
  return {
    is_installed = function()
      return opts.installed
    end,
    get_latest_version = opts.get_latest_version,
    get_installed_version = opts.get_installed_version,
    check_new_version = opts.check_new_version,
  }
end

describe("config.mason_sync", function()
  it("queues missing packages without checking versions", function()
    -- given
    local to_install = {}
    local pkg = package({ installed = false })

    -- when
    local pending = mason_sync.queue_install_or_update("stylua", pkg, to_install, function() end, function() end)

    -- then
    assert.is_false(pending)
    assert.are.same({ "stylua" }, to_install)
  end)

  it("queues outdated Mason v2 packages with the latest version", function()
    -- given
    local to_install = {}
    local pkg = package({
      installed = true,
      get_latest_version = function()
        return "2.0.0"
      end,
      get_installed_version = function()
        return "1.0.0"
      end,
    })

    -- when
    local pending = mason_sync.queue_install_or_update(
      "lua-language-server",
      pkg,
      to_install,
      function() end,
      function() end
    )

    -- then
    assert.is_false(pending)
    assert.are.same({ "lua-language-server@2.0.0" }, to_install)
  end)

  it("skips current Mason v2 packages", function()
    -- given
    local to_install = {}
    local pkg = package({
      installed = true,
      get_latest_version = function()
        return "2.0.0"
      end,
      get_installed_version = function()
        return "2.0.0"
      end,
    })

    -- when
    local pending = mason_sync.queue_install_or_update(
      "lua-language-server",
      pkg,
      to_install,
      function() end,
      function() end
    )

    -- then
    assert.is_false(pending)
    assert.are.same({}, to_install)
  end)

  it("queues outdated Mason v1 packages after the async version check", function()
    -- given
    local to_install = {}
    local pending_count = 0
    local done = false
    local pkg = package({
      installed = true,
      check_new_version = function(_, callback)
        callback(true, { version = "3.0.0" })
      end,
    })

    -- when
    local pending = mason_sync.queue_install_or_update("stylua", pkg, to_install, function()
      pending_count = pending_count + 1
    end, function()
      pending_count = pending_count - 1
      done = true
    end)

    -- then
    assert.is_true(pending)
    assert.are.equal(0, pending_count)
    assert.is_true(done)
    assert.are.same({ "stylua@3.0.0" }, to_install)
  end)
end)
