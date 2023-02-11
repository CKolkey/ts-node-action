local Buffer = {}
Buffer.__index = Buffer

-- @param lang string
-- @return self
function Buffer:new(lang)
  local buffer = {}
  buffer.lang  = lang

  return setmetatable(buffer, self)
end

function Buffer:setup(cursor)
  self.handle = vim.api.nvim_create_buf(false, true)

  vim.treesitter.start(self.handle, self.lang)
  vim.api.nvim_buf_set_option(self.handle, "filetype", self.lang)
  vim.api.nvim_buf_set_option(self.handle, "indentexpr", "nvim_treesitter#indent()")

  require("nvim-treesitter.ts_utils").get_node_at_cursor = function()
    return vim.treesitter.get_parser(self.handle, self.lang)
        :parse()[1]
        :root()
        :named_descendant_for_range(cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2])
  end
end

function Buffer:write(text)
  vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, text)
end

function Buffer:read()
  return vim.api.nvim_buf_get_lines(self.handle, 0, -1, false)
end

function Buffer:teardown()
  vim.api.nvim_buf_delete(self.handle, { force = true })
end

function Buffer:run_action()
  vim.api.nvim_buf_call(self.handle, require("ts-node-action").node_action)
end

-- SpecHelper
local SpecHelper = {}
SpecHelper.__index = SpecHelper

_G.SpecHelper = SpecHelper

-- Builds language helper for lang
-- @param lang string
-- @return self
function SpecHelper:new(lang)
  local language   = {}
  language.lang    = lang
  language.actions = require("ts-node-action.filetypes")[lang]

  return setmetatable(language, self)
end

-- Runs full integration test for text
-- @param text string|table
-- @param cursor table
-- @return table
function SpecHelper:call(text, cursor)
  if type(text) ~= "table" then
    text = { text }
  end

  local buf = Buffer:new(self.lang)
  buf:setup(cursor or { 1, 1 }) -- row, col
  buf:write(text)
  buf:run_action()
  local result = buf:read()
  buf:teardown()

  if result[2] then
    return result
  else
    return result[1]
  end
end
