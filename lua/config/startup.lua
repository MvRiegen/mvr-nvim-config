local M = {}

local function truthy(value)
  return value == true or value == 1 or value == "1" or value == "true" or value == "TRUE"
end

function M.clean_session_requested()
  return truthy(vim.g.no_session_autoload) or truthy(vim.env.NVIM_NO_SESSION)
end

return M
