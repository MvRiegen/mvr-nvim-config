local cli_args = arg
local input = assert(cli_args[1], "usage: plenary_to_junit.lua <input.log> <output.xml>")
local output = assert(cli_args[2], "usage: plenary_to_junit.lua <input.log> <output.xml>")

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

local function cdata(value)
  return "<![CDATA[" .. tostring(value):gsub("]]>", "]]]]><![CDATA[>") .. "]]>"
end

local function class_and_name(full_name)
  local classname, name = full_name:match("^(.-)%s+([^%s].*)$")
  if classname and name then
    return classname, full_name
  end
  return "plenary", full_name
end

local tests = {}
local current

for line in (read_file(input) .. "\n"):gmatch("([^\r\n]*)\r?\n") do
  local clean = strip_ansi(line)
  local status, name = clean:match("^%s*(Success)%s+%|%|%s+(.+)$")
  if not status then
    status, name = clean:match("^%s*(Fail)%s+%|%|%s+(.+)$")
  end
  if not status then
    status, name = clean:match("^%s*(Pending)%s+%|%|%s+(.+)$")
  end

  if status then
    local classname, testcase = class_and_name(name)
    current = {
      classname = classname,
      name = testcase,
      status = status,
      output = {},
    }
    tests[#tests + 1] = current
  elseif current and current.status == "Fail" then
    current.output[#current.output + 1] = clean
  end
end

if #tests == 0 then
  tests[1] = {
    classname = "plenary",
    name = "plenary output parser",
    status = "Fail",
    output = { "No Plenary test results found in " .. input },
  }
end

local failures = 0
local skipped = 0
for _, test in ipairs(tests) do
  if test.status == "Fail" then
    failures = failures + 1
  elseif test.status == "Pending" then
    skipped = skipped + 1
  end
end

local xml = {
  '<?xml version="1.0" encoding="UTF-8"?>',
  ('<testsuite name="neovim-config.unit" tests="%d" failures="%d" errors="0" skipped="%d">'):format(
    #tests,
    failures,
    skipped
  ),
}

for _, test in ipairs(tests) do
  xml[#xml + 1] = ('  <testcase classname="%s" name="%s">'):format(
    escape_attr(test.classname),
    escape_attr(test.name)
  )
  if test.status == "Fail" then
    local message = table.concat(test.output, "\n"):gsub("^%s+", "")
    xml[#xml + 1] = ('    <failure message="%s">%s</failure>'):format(escape_attr(message), cdata(message))
  elseif test.status == "Pending" then
    xml[#xml + 1] = "    <skipped />"
  end
  xml[#xml + 1] = "  </testcase>"
end

xml[#xml + 1] = "</testsuite>"

write_file(output, table.concat(xml, "\n") .. "\n")
