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
