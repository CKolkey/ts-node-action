local M = {}

-- private
-- @replacement: string|table
-- @opts: table
-- @opts.cursor: table|nil
-- @opts.cursor.row: number|nil
-- @opts.cursor.col: number|nil
local function replace_node(node, replacement, opts)
  if type(replacement) ~= "table" then
    replacement = { replacement }
  end

  local start_row, start_col, end_row, end_col = node:range()
  vim.api.nvim_buf_set_text(
    vim.api.nvim_get_current_buf(),
    start_row, start_col, end_row, end_col, replacement
  )

  if opts.cursor then
    vim.api.nvim_win_set_cursor(
      vim.api.nvim_get_current_win(),
      {
        start_row + (opts.cursor.row or 0) + 1,
        start_col + (opts.cursor.col or 0)
      }
    )
  end
end

local function info(message)
  vim.notify(message, vim.log.levels.INFO, { title = "Node Action" })
end

M.node_actions = {
  lua = require("ts-node-action/filetypes/lua"),
  json = require("ts-node-action/filetypes/json"),
  ruby = require("ts-node-action/filetypes/ruby"),
}

function M.setup(opts)
  M.node_actions = vim.tbl_deep_extend("force", M.node_actions, opts or {})
end

function M.node_action()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if not node then
    info("No node found at cursor")
    return
  end

  if not M.node_actions[vim.o.filetype] then
    info("No actions defined for filetype: '" .. vim.o.filetype .. "'")
    return
  end

  local action = M.node_actions[vim.o.filetype][node:type()]
  if action then
    local replacement, opts = action(node)
    replace_node(node, replacement, opts or {})
  else
    info("No action defined for " .. vim.o.filetype .. " node type: '" .. node:type() .. "'")
  end
end

function M.debug()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  print(vim.inspect(
    {
      node = {
        filetype = vim.o.filetype,
        node_type = node:type(),
        named = node:named(),
        named_children = node:named_child_count(),
      },
      plugin = {
        node_actions = M.node_actions
      }
    }
  ))
end

return M
