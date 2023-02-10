local Language = {}
Language.__index = Language

-- Builds language helper for lang
-- @param lang string
-- @return self
function Language:new(lang)
  local language   = {}
  language.lang    = lang
  language.actions = require("ts-node-action.filetypes")[lang]

  return setmetatable(language, self)
end

-- Parses text into a treesitter node for given language
--
-- @param text string
-- @param cursor table|nil
-- @return tsnode
function Language:build_node(text, cursor)
  cursor = cursor or { 0, 1, 0, 1 } -- { start_row, start_col, end_row, end_col }

  local tree_root = vim.treesitter.get_string_parser(text, self.lang):parse()[1]:root()
  local node      = tree_root:named_descendant_for_range(unpack(cursor))

  -- get_node_text() helper needs to be able to get the text from somewhere,
  -- and since we don't have a buffer, this is alright for now
  SpecHelper.strings[node:id()] = text

  return node
end

-- Runs a node action on node, returning result
--
-- @param node tsnode
-- @return table|string
function Language:run_action(node)
  local result, _ = self.actions[node:type()][1][1](node)
  return result
end

_G.SpecHelper = {
  strings = {},
  for_lang = function(lang)
    return Language:new(lang)
  end
}
