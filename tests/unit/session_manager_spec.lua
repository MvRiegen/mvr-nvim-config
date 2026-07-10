local test_file = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(test_file, ":p:h:h:h")
local session_manager = dofile(root .. "/lua/config/session_manager.lua")

---@type any
local assert = assert

local function reset_to_single_empty_buffer()
  vim.cmd("silent! %bwipeout!")
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, true, { "" })
  vim.bo.modified = false
end

describe("config.session_manager", function()
  before_each(reset_to_single_empty_buffer)
  after_each(reset_to_single_empty_buffer)

  it("preserves a single empty placeholder buffer", function()
    assert.is_true(session_manager.should_preserve_placeholder_buffer())
  end)

  it("does not preserve named buffers", function()
    vim.api.nvim_buf_set_name(0, root .. "/README.md")

    assert.is_false(session_manager.should_preserve_placeholder_buffer())
  end)

  it("does not preserve modified buffers", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { "changed" })
    vim.bo.modified = true

    assert.is_false(session_manager.should_preserve_placeholder_buffer())
  end)

  it("does not preserve buffers with content on multiple lines", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, true, { "", "second line" })
    vim.bo.modified = false

    assert.is_false(session_manager.should_preserve_placeholder_buffer())
  end)

  it("does not preserve the buffer when another buffer exists", function()
    vim.cmd("badd README.md")

    assert.is_false(session_manager.should_preserve_placeholder_buffer())
  end)

  it("prepares a single empty placeholder buffer", function()
    vim.cmd("edit README.md")
    vim.cmd("badd init.lua")

    local placeholder = session_manager.prepare_placeholder_buffer()
    local valid_buffers = {}

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buffer) then
        table.insert(valid_buffers, buffer)
      end
    end

    assert.are.same({ placeholder }, valid_buffers)
    assert.are.equal("", vim.api.nvim_buf_get_name(placeholder))
    assert.are.same({ "" }, vim.api.nvim_buf_get_lines(placeholder, 0, -1, true))
    assert.is_false(vim.api.nvim_get_option_value("modified", { buf = placeholder }))
  end)
end)
