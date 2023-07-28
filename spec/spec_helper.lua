local Buffer = {}

--- @class Buffer
--- @field lang string The language for this buffer
--- @field opts table Buffer local settings
--- @field setup self
--- @field teardown nil

--- @param lang string
--- @param buf_opts table
--- @return Buffer
function Buffer.new(lang, buf_opts)
  local instance = {
    lang = lang,
    opts = vim.tbl_extend("keep", {
      filetype = lang,
      indentexpr = "nvim_treesitter#indent()",
    }, buf_opts or {}),
  }

  setmetatable(instance, { __index = Buffer })

  return instance
end

--- @return self
function Buffer:setup()
  self.handle = vim.api.nvim_create_buf(false, true)
  vim.treesitter.start(self.handle, self.lang)

  for key, value in pairs(self.opts) do
    vim.api.nvim_buf_set_option(self.handle, key, value)
  end

  return self
end

-- Fakes cursor location by just returning the node at where the cursor should be
--- @param pos table 1-indexed { row, col }
--- @return self
function Buffer:set_cursor(pos)
  local row = pos[1] - 1
  local col = pos[2] - 1
  local fake_get_node = function()
    local node = vim.treesitter
      .get_parser(self.handle, self.lang)
      :parse()[1]
      :root()
      :named_descendant_for_range(row, col, row, col)
    return node, self.lang
  end

  require("ts-node-action")._get_node = fake_get_node

  return self
end

--- @param text string|table
--- @return self
function Buffer:write(text)
  if type(text) ~= "table" then
    text = { text }
  end

  vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, text)
  return self
end

--- @return table
function Buffer:read()
  return vim.api.nvim_buf_get_lines(self.handle, 0, -1, false)
end

--- @return nil
function Buffer:teardown()
  vim.api.nvim_buf_delete(self.handle, { force = true })
end

--- @return self
function Buffer:run_action()
  vim.api.nvim_buf_call(self.handle, require("ts-node-action").node_action)
  return self
end

local SpecHelper = {}

_G.SpecHelper = SpecHelper

--- @class SpecHelper A general wrapper, available in the global scope, for test related helpers
--- @field lang string The language for this buffer
--- @field buf_opts table Buffer local settings
--- @field call table

--- @param lang string
--- @param buf_opts table|nil
--- @return SpecHelper
function SpecHelper.new(lang, buf_opts)
  local instance = {
    lang = lang,
    buf_opts = buf_opts or {},
  }

  setmetatable(instance, { __index = SpecHelper })

  return instance
end

-- Runs full integration test for text
-- Returns full buffer text as a table, one string per line.
--
--- @param text string|table
--- @param pos table|nil 1-indexed, { row, col }. Defaults to first line, first col if empty
--- @return table
function SpecHelper:call(text, pos)
  local buffer = Buffer.new(self.lang, self.buf_opts)
  local result =
    buffer:setup():set_cursor(pos or { 1, 1 }):write(text):run_action():read()

  buffer:teardown()

  return result
end
