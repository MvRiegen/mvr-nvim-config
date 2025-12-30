local function is_aarch64()
  local uname = (vim.uv or vim.loop).os_uname()
  return uname and uname.machine == "aarch64"
end

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

local function download(url, out, sync)
  local cmd
  if vim.fn.executable("curl") == 1 then
    cmd = { "curl", "-L", "-o", out, url }
  elseif vim.fn.executable("wget") == 1 then
    cmd = { "wget", "-O", out, url }
  else
    vim.notify("platform-tools: curl/wget not found", vim.log.levels.WARN)
    return false
  end

  local job = vim.system(cmd)
  if sync then
    local result = job:wait()
    return result.code == 0
  end
  return true
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

local function install_lemminx(cfg, sync)
  local jar_path = cfg.lemminx_jar
  if vim.fn.filereadable(jar_path) == 1 and is_valid_jar(jar_path) then
    return
  end
  ensure_dir(cfg.lemminx_dir)
  local urls = cfg.lemminx_urls or cfg.lemminx_url or {}
  if type(urls) == "string" then
    urls = { urls }
  end

  for _, url in ipairs(urls) do
    if vim.fn.filereadable(jar_path) == 1 then
      (vim.uv or vim.loop).fs_unlink(jar_path)
    end
    download(url, jar_path, sync)
    if is_valid_jar(jar_path) then
      return
    end
  end
  if vim.fn.filereadable(jar_path) == 1 then
    (vim.uv or vim.loop).fs_unlink(jar_path)
  end
  vim.notify("platform-tools: failed to download a valid lemminx jar; set vim.g.platform_tools.lemminx_url", vim.log.levels.WARN)
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
  end
end

local function run_install(sync)
  if not is_aarch64() then
    return
  end

  local defaults = {
    lemminx_dir = vim.fn.expand("~/.local/share/lemminx"),
    lemminx_jar = vim.fn.expand("~/.local/share/lemminx/lemminx.jar"),
    lemminx_urls = {
      "https://github.com/eclipse/lemminx/releases/latest/download/org.eclipse.lemminx-uber.jar",
      "https://download.eclipse.org/lemminx/releases/latest/org.eclipse.lemminx-uber.jar",
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
