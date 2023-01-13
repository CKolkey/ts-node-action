local M = {}

-- private
-- @param replacement string|table
-- @param opts table
-- @param opts.cursor table|nil
-- @param opts.cursor.row number|nil
-- @param opts.cursor.col number|nil
-- @param opts.callback function|nil
-- @param opts.format boolean|nil
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

  if opts.format then
    vim.cmd("silent! normal! " .. #replacement .. "==")
  end

  if opts.callback then
    opts.callback()
  end
end

-- @private
-- @param message string
-- @return nil
local function info(message)
  vim.notify(message, vim.log.levels.INFO, { title = "Node Action", icon = " " })
end

-- @private
-- @param action function
-- @param node tsnode
-- @return nil
local function do_action(action, node)
  local replacement, opts = action(node)
  if replacement then
    replace_node(node, replacement, opts or {})
  else
    info("Action returned nil")
  end
end

-- @private
-- @param node tsnode
-- @return function|nil
local function find_action(node)
  local type = node:type()
  if M.node_actions[vim.o.filetype] and M.node_actions[vim.o.filetype][type] then
    return M.node_actions[vim.o.filetype][type]
  else
    return M.node_actions["*"][type]
  end
end

M.node_actions = require("ts-node-action.filetypes")

-- @param opts? table
-- @return nil
function M.setup(opts)
  M.node_actions = vim.tbl_deep_extend("force", M.node_actions, opts or {})
end

function M.node_action()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if not node then
    info("No node found at cursor")
    return
  end

  local action = find_action(node)
  if type(action) == "function" then
    do_action(action, node)
  elseif type(action) == "table" then
    vim.ui.select(
      action,
      {
        prompt = "Select Action",
        format_item = function(choice)
          return choice.name
        end
      },
      function(choice) do_action(choice[1], node) end
    )
  else
    info("No action defined for '" .. vim.o.filetype .. "' node type: '" .. node:type() .. "'")
  end
end

function M.debug()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if not node then
    info("No node found at cursor")
    return
  end

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
