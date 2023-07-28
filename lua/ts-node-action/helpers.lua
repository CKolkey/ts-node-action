local M = {}

-- Returns node text as a string if single-line, or table if multi-line
--
--- @param node TSNode
--- @return table|string|nil
function M.node_text(node)
  if not node then
    return
  end

  local text
  if vim.treesitter.get_node_text then
    text = vim.trim(
      vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
    )
  else
    -- TODO: Remove in 0.10
    text = vim.trim(
      vim.treesitter.query.get_node_text(node, vim.api.nvim_get_current_buf())
    )
  end

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
--     " %s ",
--     ["is"] = "%s ",
--   },
-- }
-- The ["is"] key under "not" overrides the format to remove the space when the
-- previous text is "is".
-- A ["prev_nil"] key will match when there is no previous node text
-- A ["next_nil"] key will match when there is no next node text
-- If none of the context_prev's apply, the string in index 1 will be used
-- See filetypes/python.lua or filetypes/ruby.lua for more examples
--
--- @param node TSNode
--- @param padding table
--- @return string|table|nil
function M.padded_node_text(node, padding)
  local text = M.node_text(node)
  local format = padding[text]

  if not format then
    return text
  end

  if type(format) == "table" then
    local context_prev = M.node_text(node:prev_sibling())
    local context_next = M.node_text(node:next_sibling())

    if format[context_prev] then
      format = format[context_prev]
    elseif not context_prev and format["prev_nil"] then
      format = format["prev_nil"]
    elseif format[context_next] then
      format = format[context_next]
    elseif not context_next and format["next_nil"] then
      format = format["next_nil"]
    else
      format = format[1]
    end
  end

  return string.format(format, text)
end

-- Prints out a node's tree, showing each child's index, type, text, and ID
--
--- @param node TSNode
--- @return nil
function M.debug_print_tree(node)
  local tree = {}
  local index = 1
  for child, id in node:iter_children() do
    tree[tostring(index)] =
      { type = child:type(), text = M.node_text(child), id = id }
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
