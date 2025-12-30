local function is_aarch64()
  local uname = (vim.uv or vim.loop).os_uname()
  return uname and uname.machine == "aarch64"
end

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

local function notify_platform_tools_updated()
  if not vim.api.nvim_exec_autocmds then
    return
  end
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "PlatformToolsUpdated" })
  end)
end

local function is_valid_jar(path)
  local uv = (vim.uv or vim.loop)
  local stat = uv.fs_stat(path)
  if not stat or (stat.size or 0) < 1024 then
    return false
  end
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return false
  end
  local data = uv.fs_read(fd, 2, 0)
  uv.fs_close(fd)
  if not data or #data < 2 then
    return false
  end
  return data == "PK"
end

local function download(url, out, sync, on_success)
  local tmp = out .. ".part"
  if vim.fn.filereadable(tmp) == 1 then
    (vim.uv or vim.loop).fs_unlink(tmp)
  end

  local cmd
  if vim.fn.executable("curl") == 1 then
    cmd = { "curl", "-fL", "--retry", "3", "--retry-delay", "1", "--connect-timeout", "10", "-o", tmp, url }
  elseif vim.fn.executable("wget") == 1 then
    cmd = { "wget", "--tries=3", "--timeout=10", "-O", tmp, url }
  else
    vim.notify("platform-tools: curl/wget not found", vim.log.levels.WARN)
    return false
  end

  local function finalize(ok)
    if ok and is_valid_jar(tmp) then
      local uv = (vim.uv or vim.loop)
      uv.fs_rename(tmp, out)
      if on_success then
        on_success(out)
      end
      return true
    end
    if vim.fn.filereadable(tmp) == 1 then
      (vim.uv or vim.loop).fs_unlink(tmp)
    end
    return false
  end

  if sync then
    local result = vim.system(cmd):wait()
    return finalize(result.code == 0)
  end

  vim.system(cmd, {}, function(res)
    finalize(res.code == 0)
  end)
  return true
end

local function install_lemminx(cfg, sync)
  local jar_path = cfg.lemminx_jar
  if vim.fn.filereadable(jar_path) == 1 and is_valid_jar(jar_path) then
    return
  end
  if vim.fn.filereadable(jar_path) == 1 then
    (vim.uv or vim.loop).fs_unlink(jar_path)
  end
  ensure_dir(cfg.lemminx_dir)
  local urls = cfg.lemminx_urls or cfg.lemminx_url or {}
  if type(urls) == "string" then
    urls = { urls }
  end

  local function try_url(index)
    if index > #urls then
      vim.notify("platform-tools: failed to download a valid lemminx jar; set vim.g.platform_tools.lemminx_url", vim.log.levels.WARN)
      return
    end
    local url = urls[index]
    if sync then
      if download(url, jar_path, true, notify_platform_tools_updated) then
        return
      end
      return try_url(index + 1)
    end
    download(url, jar_path, false, notify_platform_tools_updated)
    -- For async installs, we don't chain retries; next run will retry if invalid.
  end

  try_url(1)
end

local function find_clangd_target(candidates)
  for _, name in ipairs(candidates) do
    if vim.fn.executable(name) == 1 then
      return vim.fn.exepath(name)
    end
  end
end

local function link_clangd(cfg)
  local link_path = cfg.clangd_link
  if vim.fn.executable(link_path) == 1 then
    return
  end

  local target = find_clangd_target(cfg.clangd_candidates)
  if not target or target == "" then
    vim.notify("platform-tools: clangd not found in PATH", vim.log.levels.WARN)
    return
  end

  local link_dir = vim.fn.fnamemodify(link_path, ":h")
  ensure_dir(link_dir)

  local ftype = vim.fn.getftype(link_path)
  if ftype ~= "" then
    return
  end

  local ok, err = (vim.uv or vim.loop).fs_symlink(target, link_path)
  if not ok then
    vim.notify("platform-tools: failed to link clangd: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  notify_platform_tools_updated()
end

local function run_install(sync)
  if not is_aarch64() then
    return
  end

  local defaults = {
    lemminx_dir = vim.fn.expand("~/.local/share/lemminx"),
    lemminx_jar = vim.fn.expand("~/.local/share/lemminx/lemminx.jar"),
    lemminx_urls = {
      "https://download.eclipse.org/staging/2025-09/plugins/org.eclipse.lemminx.uber-jar_0.31.0.jar",
    },
    clangd_link = vim.fn.expand("~/.local/share/clangd/bin/clangd"),
    clangd_candidates = { "clangd-16", "clangd" },
  }

  local cfg = vim.tbl_deep_extend("force", defaults, vim.g.platform_tools or {})

  install_lemminx(cfg, sync)
  link_clangd(cfg)
end

return {
  dir = vim.fn.stdpath("config"),
  name = "platform-tools",
  event = "VimEnter",
  cmd = { "PlatformToolsInstall", "PlatformToolsInstallSync" },
  config = function()
    vim.api.nvim_create_user_command("PlatformToolsInstall", function()
      run_install(false)
    end, {})
    vim.api.nvim_create_user_command("PlatformToolsInstallSync", function()
      run_install(true)
    end, {})
    vim.defer_fn(function()
      run_install(false)
    end, 3000)
  end,
}
