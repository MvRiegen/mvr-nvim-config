local M = {}

function M.is_arm64_machine(machine)
  if type(machine) ~= "string" then
    return false
  end

  machine = machine:lower()
  return machine == "aarch64" or machine == "arm64"
end

local function machine_arch()
  local uv = vim.uv or vim.loop
  if not uv or type(uv.os_uname) ~= "function" then
    return ""
  end
  local uname = uv.os_uname()
  local machine = uname and uname.machine or ""
  if type(machine) ~= "string" then
    return ""
  end
  return machine:lower()
end

function M.is_arm64()
  return M.is_arm64_machine(machine_arch())
end

function M.is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

function M.has_msvc_cl()
  return vim.fn.executable("cl") == 1
end

M.formatter_exec = {
  stylua = "stylua",
  ruff_format = "ruff",
  ruff_organize_imports = "ruff",
  phpcbf = "phpcbf",
  rubocop = "rubocop",
  prettier = "prettier",
  ["puppet-lint"] = "puppet-lint",
  xmllint = "xmllint",
  shfmt = "shfmt",
}

M.formatters_by_ft = {
  lua = { "stylua" },
  python = { "ruff_format", "ruff_organize_imports" },
  php = { "phpcbf" },
  ruby = { "rubocop" },
  puppet = { "puppet-lint" },
  markdown = { "prettier" },
  json = { "prettier" },
  yaml = { "prettier" },
  typescript = { "prettier" },
  xml = { "xmllint" },
  html = { "prettier" },
  ["*"] = { "trim_whitespace" },
  sh = { "shfmt" },
  bash = { "shfmt" },
  zsh = { "shfmt" },
}

M.linters_by_ft = {
  lua = { "luacheck" },
  python = { "ruff" },
  php = { "phpcs" },
  markdown = { "markdownlint" },
  puppet = { "puppet-lint" },
  ruby = { "rubocop" },
  yaml = { "yamllint" },
  json = { "jsonlint" },
  typescript = { "eslint_d" },
  html = { "htmlhint" },
  xml = { "xmllint" },
  sh = { "shellcheck" },
  bash = { "shellcheck" },
  zsh = { "shellcheck" },
  make = { "checkmake" },
  dockerfile = { "hadolint" },
}

M.default_mason_tools = {
  "stylua",
  "ruff",
  "phpcbf",
  "rubocop",
  "prettier",
  "luacheck",
  "phpcs",
  "markdownlint",
  "yamllint",
  "jsonlint",
  "eslint_d",
  "htmlhint",
  "puppet-lint",
  "shfmt",
  "shellcheck",
  "checkmake",
  "hadolint",
}

local function without_tools(tools, excluded)
  local filtered = {}
  for _, tool in ipairs(tools) do
    if not excluded[tool] then
      filtered[#filtered + 1] = tool
    end
  end
  return filtered
end

function M.filter_mason_tools(tools, opts)
  opts = opts or {}
  local filtered = without_tools(tools, {})

  if opts.is_arm64 then
    filtered = without_tools(filtered, { checkmake = true })
  end

  if opts.is_windows and not opts.has_msvc_cl then
    filtered = without_tools(filtered, { luacheck = true })
  end

  return filtered
end

M.mason_tools = M.filter_mason_tools(M.default_mason_tools, {
  is_arm64 = M.is_arm64(),
  is_windows = M.is_windows(),
  has_msvc_cl = M.has_msvc_cl(),
})

M.npm_tools = {
  prettier = true,
  markdownlint = true,
  jsonlint = true,
  eslint_d = true,
  htmlhint = true,
}

function M.unwrap_cmd(cmd)
  if type(cmd) == "table" then
    return cmd[1]
  end
  return cmd
end

function M.is_executable(cmd)
  cmd = M.unwrap_cmd(cmd)
  if type(cmd) ~= "string" then
    return true
  end
  return vim.fn.executable(cmd) == 1
end

return M
