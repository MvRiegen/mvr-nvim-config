local M = {}

local function version_from_info(version_info)
  if type(version_info) == "table" then
    return version_info.version
  end
  if type(version_info) == "string" then
    return version_info
  end
  return nil
end

local function package_spec(name, version)
  if type(version) == "string" and version ~= "" then
    return name .. "@" .. version
  end
  return name
end

local function safe_call(method, pkg)
  local ok, result = pcall(method, pkg)
  if ok then
    return result
  end
  return nil
end

function M.queue_install_or_update(name, pkg, to_install, on_pending_start, on_pending_done)
  on_pending_start = on_pending_start or function() end
  on_pending_done = on_pending_done or function() end

  if not pkg:is_installed() then
    table.insert(to_install, name)
    return false
  end

  if type(pkg.get_latest_version) == "function" and type(pkg.get_installed_version) == "function" then
    local latest_version = safe_call(pkg.get_latest_version, pkg)
    local installed_version = safe_call(pkg.get_installed_version, pkg)
    if latest_version and installed_version and latest_version ~= installed_version then
      table.insert(to_install, package_spec(name, latest_version))
    end
    return false
  end

  if type(pkg.check_new_version) == "function" then
    on_pending_start()
    pkg:check_new_version(function(ok, version_info)
      if ok then
        table.insert(to_install, package_spec(name, version_from_info(version_info)))
      end
      on_pending_done()
    end)
    return true
  end

  return false
end

return M
