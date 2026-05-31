local input = assert(arg[1], "usage: checkstyle_from_log.lua <input.log> <output.xml> <tool>")
local output = assert(arg[2], "usage: checkstyle_from_log.lua <input.log> <output.xml> <tool>")
local tool = arg[3] or "static-analysis"

local function read_file(path)
  local file = assert(io.open(path, "r"))
  local data = file:read("*a")
  file:close()
  return data
end

local function write_file(path, data)
  local file = assert(io.open(path, "w"))
  file:write(data)
  file:close()
end

local function strip_ansi(line)
  return line:gsub("\27%[[0-9;]*m", "")
end

local function escape_attr(value)
  return tostring(value)
    :gsub("&", "&amp;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
    :gsub('"', "&quot;")
    :gsub("'", "&apos;")
end

local function severity(value)
  value = tostring(value or "warning"):lower()
  if value == "error" then
    return "error"
  end
  return "warning"
end

local function parse_luals(line)
  local file, line_number, column, level, message =
    line:match("^%s*([^:]+):(%d+):(%d+)%s+%[([^%]]+)%]%s+(.+)$")
  if not file then
    return nil
  end
  return {
    file = file:gsub("\\", "/"),
    line = line_number,
    column = column,
    severity = severity(level),
    message = message,
  }
end

local function parse_luacheck(line)
  local file, line_number, column, message = line:match("^%s*([^:]+):(%d+):(%d+):%s+(.+)$")
  if not file then
    return nil
  end
  return {
    file = file:gsub("\\", "/"),
    line = line_number,
    column = column,
    severity = "warning",
    message = message,
  }
end

local parsers = {
  luals = parse_luals,
  luacheck = parse_luacheck,
}

local parser = parsers[tool] or parse_luacheck
local issues_by_file = {}
local files = {}

for raw_line in (read_file(input) .. "\n"):gmatch("([^\r\n]*)\r?\n") do
  local issue = parser(strip_ansi(raw_line))
  if issue then
    if not issues_by_file[issue.file] then
      issues_by_file[issue.file] = {}
      files[#files + 1] = issue.file
    end
    table.insert(issues_by_file[issue.file], issue)
  end
end

table.sort(files)

local xml = {
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<checkstyle version="4.3">',
}

for _, file in ipairs(files) do
  xml[#xml + 1] = ('  <file name="%s">'):format(escape_attr(file))
  for _, issue in ipairs(issues_by_file[file]) do
    xml[#xml + 1] = ('    <error line="%s" column="%s" severity="%s" message="%s" source="%s" />'):format(
      escape_attr(issue.line),
      escape_attr(issue.column),
      escape_attr(issue.severity),
      escape_attr(issue.message),
      escape_attr(tool)
    )
  end
  xml[#xml + 1] = "  </file>"
end

xml[#xml + 1] = "</checkstyle>"

write_file(output, table.concat(xml, "\n") .. "\n")
