local Buffer = {}
Buffer.__index = Buffer

-- Creates a new Buffer object for testing. Custom buf options can be passed into constructor.
-- @param lang string
-- @param user_opts table
-- @return Buffer
function Buffer:new(lang, buf_opts)
  local buffer = {}
  buffer.lang  = lang
  buffer.opts  = vim.tbl_extend(
    "keep",
    { filetype = lang, indentexpr = "nvim_treesitter#indent()" },
    buf_opts or {}
  )

  return setmetatable(buffer, self)
end

-- @return Buffer
function Buffer:setup()
  self.handle = vim.api.nvim_create_buf(false, true)
  vim.treesitter.start(self.handle, self.lang)

  for key, value in pairs(self.opts) do
    vim.api.nvim_buf_set_option(self.handle, key, value)
  end

  return self
end

-- Fakes cursor location by just returning the node at where the cursor should be
-- 1-indexed { row, col }, like vim.fn.getpos(".")
--
-- @param pos table
-- @return Buffer
function Buffer:set_cursor(pos)
  local row = pos[1] - 1
  local col = pos[2] - 1
  local fake_get_node_at_cursor = function()
    return vim.treesitter.get_parser(self.handle, self.lang)
        :parse()[1]
        :root()
        :named_descendant_for_range(row, col, row, col)
  end

  require("nvim-treesitter.ts_utils").get_node_at_cursor = fake_get_node_at_cursor

  return self
end

-- @param text string|table
-- @return Buffer
function Buffer:write(text)
  if type(text) ~= "table" then
    text = { text }
  end

  vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, text)
  return self
end

-- @return table
function Buffer:read()
  return vim.api.nvim_buf_get_lines(self.handle, 0, -1, false)
end

-- @return nil
function Buffer:teardown()
  vim.api.nvim_buf_delete(self.handle, { force = true })
end

-- @return Buffer
function Buffer:run_action()
  vim.api.nvim_buf_call(self.handle, require("ts-node-action").node_action)
  return self
end

-- SpecHelper - A general wrapper, available in the global scope, for test related helpers
local SpecHelper = {}
SpecHelper.__index = SpecHelper

_G.SpecHelper = SpecHelper

-- Builds language helper. Custom buffer opts can also be set on a per-filetype basis.
-- @param lang string
-- @param buf_opts table|nil
-- @return SpecHelper
function SpecHelper:new(lang, buf_opts)
  local language    = {}
  language.lang     = lang
  language.buf_opts = buf_opts or {}

  return setmetatable(language, self)
end

-- Runs full integration test for text
-- Cursor (pos) is 1-indexed, { row, col }. Defaults to first line, first col if empty
-- Returns full buffer text as a table, one string per line.
--
-- @param text string|table
-- @param pos table|nil
-- @return table
function SpecHelper:call(text, pos)
  local buffer = Buffer:new(self.lang, self.buf_opts)
  local result = buffer:setup()
      :set_cursor(pos or { 1, 1 })
      :write(text)
      :run_action()
      :read()

  buffer:teardown()

  return result
end
