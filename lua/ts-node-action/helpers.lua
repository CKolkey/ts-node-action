local M = {}

-- Returns node text as a string
--
-- @param node tsnode
-- @return string
function M.node_text(node)
  return vim.treesitter.query.get_node_text(node, vim.api.nvim_get_current_buf())
end

-- Determine if a node spans multiple lines
--
-- @param node tsnode
-- @return boolean
-- @deprecated
function M.multiline_node(node)
  print("(TS-NODE-ACTION) helpers.multiline_node() is deprecated! Update your calls to helpers.node_is_multiline()")
  return not M.node_is_multiline(node)
end

-- Determine if a node spans multiple lines
--
-- @param node tsnode
-- @return boolean
function M.node_is_multiline(node)
  local start_row, _, end_row, _ = node:range()
  return start_row ~= end_row
end

-- Adds whitespace to some unnamed nodes for nicer formatting
-- `padding` is a table where the key is the text of the unnamed node, and the value
-- is a format string. The following would add a space after commas:
-- { [","] = "%s " }
--
-- The prev_text is used for rare cases where the padding of an unnamed node
-- is different depending on the text of the previous node.  For example, in
-- python, `is` and `not` are separate unnamed nodes, even when seen
-- together as `is not`. So we can write a padding rule that includes the
-- previous node's text as:
-- {
--   ["is"]  = " %s ",
--   ["not"] = {
--     [""]   = " %s ",
--     ["is"] = "%s ",
--   },
-- }
-- The ["is"] key under "not" overrides the format to remove the space when the
-- previous text is "is".
-- A [""] key is a catch-all for any non-nil prev_text.
-- A ["nil"] key will match when prev_text == nil.
-- See filetypes/python.lua for more info.
--
-- @param node tsnode
-- @param padding table
-- @param prev_text string|nil The [presumed padded] text of the previous node.
-- @return string
function M.padded_node_text(node, padding, prev_text)
  local text = M.node_text(node)

  if padding[text] then
    local cfg = padding[text]

    if type(cfg) == "table" then
      prev_text = prev_text and vim.trim(prev_text)

      if cfg[prev_text] then
        text = string.format(cfg[prev_text], text)
      elseif cfg["nil"] and prev_text == nil then
        text = string.format(cfg["nil"], text)
      elseif cfg[""] then
        text = string.format(cfg[""], text)
      end

    else
      text = string.format(cfg, text)
    end
  end

  return text
end

-- Prints out a node's tree, showing each child's index, type, text, and ID
--
-- @param node tsnode
-- @return nil
function M.debug_print_tree(node)
  local tree  = {}
  local index = 1
  for child, id in node:iter_children() do
    tree[tostring(index)] = { type = child:type(), text = M.node_text(child), id = id }
    index = index + 1
  end

  vim.pretty_print(tree)
end

-- Dissassembles a node tree into it's named and unnamed parts
--
-- @param node tsnode
-- @return table
function M.destructure_node(node)
  local structure = {}
  for child, id in node:iter_children() do
    structure[id or child:type()] = vim.trim(M.node_text(child))
  end

  return structure
end

return M
