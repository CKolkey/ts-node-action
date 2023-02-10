local M = {}

-- Returns node text as a string
--
-- @param node tsnode
-- @return string
function M.node_text(node)
  local source
  if vim.fn.environ()["TS_NODE_ACTION_ENV_TEST"] then
    source = SpecHelper.strings[node:id()]
  else
    source = vim.api.nvim_get_current_buf()
  end

  return vim.treesitter.query.get_node_text(node, source)
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
-- @param node tsnode
-- @param padding table
-- @return string
function M.padded_node_text(node, padding)
  local text = M.node_text(node)

  if padding[text] then
    text = string.format(padding[text], text)
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
