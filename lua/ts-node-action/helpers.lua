local M = {}

-- Returns node text as a string if single-line, or table if multi-line
--
--- @param node TSNode
--- @return table|string|nil
function M.node_text(node)
  if not node then return end

  local text = vim.trim(vim.treesitter.query.get_node_text(node, 0))
  if text:match("\n") then
    return vim.tbl_map(vim.trim, vim.split(text, "\n"))
  else
    return text
  end
end

-- Determine if a node spans multiple lines
--
--- @param node TSNode
--- @return boolean
function M.node_is_multiline(node)
  local start_row, _, end_row, _ = node:range()
  return start_row ~= end_row
end

-- Adds whitespace to some unnamed nodes for nicer formatting
-- `padding` is a table where the key is the text of the unnamed node, and the
-- value is a format string. The following would add a space after commas:
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
--- @param node TSNode
--- @param padding table
--- @param context string|nil The [presumed padded] text of the previous node.
--- @return string
function M.padded_node_text(node, padding, context)
  local text = M.node_text(node)

  if padding[text] then
    local format = padding[text]

    if type(format) == "table" then
      context = context and vim.trim(context)

      if format[context] then
        text = string.format(format[context], text)
      elseif format["nil"] and context == nil then
        text = string.format(format["nil"], text)
      elseif format[""] then
        text = string.format(format[""], text)
      end

    else
      text = string.format(format, text)
    end
  end

  return text
end

-- Prints out a node's tree, showing each child's index, type, text, and ID
--
--- @param node TSNode
--- @return nil
function M.debug_print_tree(node)
  local tree  = {}
  local index = 1
  for child, id in node:iter_children() do
    tree[tostring(index)] = { type = child:type(), text = M.node_text(child), id = id }
    index = index + 1
  end

  vim.pretty_print(tree)
end

-- Disassembles a node tree into it's named and unnamed parts
--
--- @param node TSNode
--- @return table
function M.destructure_node(node)
  local structure = {}
  for child, id in node:iter_children() do
    structure[id or child:type()] = M.node_text(child)
  end

  return structure
end

return M
