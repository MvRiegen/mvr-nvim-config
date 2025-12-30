local M = {}

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

M.mason_tools = {
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

M.npm_tools = {
  prettier = true,
  markdownlint = true,
  jsonlint = true,
  eslint_d = true,
  htmlhint = true,
}

local function unwrap_cmd(cmd)
  if type(cmd) == "table" then
    return cmd[1]
  end
  return cmd
end

function M.is_executable(cmd)
  cmd = unwrap_cmd(cmd)
  if type(cmd) ~= "string" then
    return true
  end
  return vim.fn.executable(cmd) == 1
end

return M
