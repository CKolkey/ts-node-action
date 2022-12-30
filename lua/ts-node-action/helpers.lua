local M = {}

-- Returns node text as a string
function M.node_text(node)
  return vim.treesitter.query.get_node_text(node, vim.api.nvim_get_current_buf())
end

-- Determine if a node spans multiple lines
function M.multiline_node(node)
  local start_row, _, end_row, _ = node:range()
  return start_row == end_row
end

-- left-pad text with spaces. If indent is a ts-node, assume we want the starting column
-- offset can be used to add extra padding
function M.indent_text(text, indent, offset)
  offset = offset or 0

  if type(indent) == "userdata" then
    _, indent = indent:start()
  end

  return (" "):rep(indent + offset) .. text
end

-- Combine node_text() and indent_text(). Offset can be used to add extra padding
function M.indent_node_text(node, offset)
  local start_row = node:start()
  local indent = vim.fn.indent(start_row + 1)

  return M.indent_text(M.node_text(node), indent, offset)
end

-- Adds whitespace to some unnamed nodes for nicer formatting
-- `padding` is a table where the key is the text of the unnamed node, and the value
-- is a format string. The following would add a space after commas:
-- { [","] = "%s " }
function M.padded_node_text(node, padding)
  local text = M.node_text(node)

  if padding[text] then
    text = string.format(padding[text], text)
  end

  return text
end

return M
