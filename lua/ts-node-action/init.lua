local M = {}

-- private
-- @replacement: string|table
-- @opts: table
-- @opts.cursor: table|nil
-- @opts.cursor.row: number|nil
-- @opts.cursor.col: number|nil
-- @opts.callback: function|nil
-- @opts.format: boolean|nil
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
    vim.cmd("silent! normal " .. #replacement .. "==")
  end

  if opts.callback then
    opts.callback()
  end
end

-- @private
-- @message: string
-- @return: nil
local function info(message)
  vim.notify(message, vim.log.levels.INFO, { title = "Node Action", icon = " " })
end

-- @private
-- @action: function
-- @node: tsnode
-- @return: nil
local function do_action(action, node)
  local replacement, opts = action(node)
  if replacement then
    replace_node(node, replacement, opts or {})
  else
    info("Action returned nil")
  end
end

M.ft_node_actions = require("ts-node-action.filetypes")

function M.setup(opts)
  M.ft_node_actions = vim.tbl_deep_extend("force", M.ft_node_actions, opts or {})
end

function M.node_action()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if not node then
    info("No node found at cursor")
    return
  end

  local action
  if M.ft_node_actions[vim.o.filetype] and M.ft_node_actions[vim.o.filetype][node:type()] then
    action = M.ft_node_actions[vim.o.filetype][node:type()]
  else
    action = M.ft_node_actions["*"][node:type()]
  end

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
        node_actions = M.ft_node_actions
      }
    }
  ))
end

return M
