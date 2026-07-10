local M = {}

local function session_restore_depth()
  return vim.g.mvr_session_restore_depth or 0
end

function M.session_restore_in_progress()
  return session_restore_depth() > 0
end

function M.with_session_restore_guard(callback)
  vim.g.mvr_session_restore_depth = session_restore_depth() + 1

  local ok, result = xpcall(callback, debug.traceback)

  vim.g.mvr_session_restore_depth = math.max(session_restore_depth() - 1, 0)

  if not ok then
    error(result)
  end

  return result
end

function M.should_preserve_placeholder_buffer()
  local current_buffer = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(current_buffer) then
    return false
  end

  local valid_buffers = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then
      table.insert(valid_buffers, buffer)
    end
  end

  if #valid_buffers ~= 1 or valid_buffers[1] ~= current_buffer then
    return false
  end

  if vim.api.nvim_buf_get_name(current_buffer) ~= "" then
    return false
  end

  if vim.api.nvim_get_option_value("modified", { buf = current_buffer }) then
    return false
  end

  if vim.api.nvim_buf_line_count(current_buffer) > 1 then
    return false
  end

  local first_line = vim.api.nvim_buf_get_lines(current_buffer, 0, 1, true)[1]
  return first_line == nil or first_line == ""
end

function M.load_session_with_placeholder(filename, utils)
  utils.active_session_filename = filename

  local swapfile = vim.o.swapfile
  local ok, err = xpcall(function()
    M.with_session_restore_guard(function()
      vim.o.swapfile = false

      vim.api.nvim_exec_autocmds("User", { pattern = "SessionLoadPre" })
      vim.api.nvim_command("silent source " .. filename)
      vim.api.nvim_exec_autocmds("User", { pattern = "SessionLoadPost" })
    end)
  end, debug.traceback)

  vim.o.swapfile = swapfile

  if not ok then
    error(err)
  end
end

function M.prepare_placeholder_buffer()
  vim.cmd("silent! noautocmd enew")

  local placeholder = vim.api.nvim_get_current_buf()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) and buffer ~= placeholder then
      pcall(vim.api.nvim_buf_delete, buffer, { force = true })
    end
  end

  -- Keep the startup placeholder out of generic empty-buffer cleanup.
  vim.bo[placeholder].buflisted = false
  vim.api.nvim_buf_set_lines(placeholder, 0, -1, true, { "" })
  vim.bo[placeholder].modified = false

  return placeholder
end

function M.schedule_startup_session_load(filename, utils)
  if utils._mvr_pending_session_load then
    return
  end

  utils._mvr_pending_session_load = true

  vim.schedule(function()
    utils._mvr_pending_session_load = nil

    if vim.fn.filereadable(filename) ~= 1 then
      return
    end

    -- Let lazy.nvim finish replaying VimEnter for startup-loaded plugins first.
    -- Afterwards recreate a single empty buffer that the session file can wipe.
    M.prepare_placeholder_buffer()
    M.load_session_with_placeholder(filename, utils)
  end)
end

function M.patch_load_session()
  local utils = require("session_manager.utils")

  if utils._mvr_load_session_patched then
    return
  end

  local original_load_session = utils.load_session

  utils.load_session = function(filename, discard_current)
    if not M.should_preserve_placeholder_buffer() then
      return original_load_session(filename, discard_current)
    end

    -- Startup session restore runs during lazy.nvim's VimEnter replay.
    -- Defer the actual :source until that replay is done, then hand the
    -- session file a fresh empty buffer it can wipe itself.
    M.schedule_startup_session_load(filename, utils)
  end

  utils._mvr_load_session_patched = true
end

return M
