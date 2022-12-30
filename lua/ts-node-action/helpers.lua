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
function M.indent_text(text, indent, offset)
  offset = offset or 0

  if type(indent) == "userdata" then
    _, indent = indent:start()
  end

  return (" "):rep(indent + offset) .. text
end

-- Combine node_text() and indent_text(). Offset can be used to add extra padding
function M.indent_node_text(node, offset)
  offset = offset or 0

  local start_row, _, _, _ = node:range()
  local indent = vim.fn.indent(start_row + 1)

  return M.indent_text(M.node_text(node), indent + offset)
end

-- Adds whitespace to some unnamed nodes for nicer formatting
-- padding is a table where the key is the text of the unnamed node, and the value
-- is a format string, ie, "%s "
function M.padded_node_text(node, padding)
  local text = M.node_text(node)

  if padding[text] then
    text = string.format(padding[text], text)
  end

  return text
end

-- replace node with provided replacement.
-- `replacement` can be string or table value
-- `opts` can be used to specify if the cursor position needs to be updated
-- after replacing text
function M.replace_node(node, replacement, opts)
  if type(replacement) ~= "table" then
    replacement = { replacement }
  end

  opts = opts or {}

  local start_row, start_col, end_row, end_col = node:range()
  vim.api.nvim_buf_set_text(
    vim.api.nvim_get_current_buf(),
    start_row,
    start_col,
    end_row,
    end_col,
    replacement
  )

  if opts.cursor then
    local position
    if type(opts.cursor) == "boolean" then
      position = { start_row + 1, start_col }
    elseif type(opts.cursor) == "table" then
      position = {
        start_row + 1 + (opts.cursor.row or 0),
        start_col + (opts.cursor.col or 0)
      }
    end

    vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), position)
  end
end

return M
