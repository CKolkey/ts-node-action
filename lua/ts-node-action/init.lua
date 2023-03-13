---@alias TSNode userdata

local M = {}

--- @private
--- @param replacement string|table
--- @param opts { cursor: { col: number, row: number }, callback: function, format: boolean, target: TSNode }
--- All opts fields are optional
local function replace_node(node, replacement, opts)
  if type(replacement) ~= "table" then
    replacement = { replacement }
  end

  local start_row, start_col, end_row, end_col = (opts.target or node):range()
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

--- @private
--- @param message string
--- @return nil
local function info(message)
  vim.notify(message, vim.log.levels.INFO, { title = "Node Action", icon = " " })
end

--- @private
--- @param action function
--- @param node TSNode
--- @return nil
local function do_action(action, node)
  local replacement, opts = action(node)
  if replacement then
    replace_node(node, replacement, opts or {})
  end
end

--- @private
--- @param node TSNode
--- @return function|nil
local function find_action(node)
  local type = node:type()
  if M.node_actions[vim.o.filetype] and M.node_actions[vim.o.filetype][type] then
    return M.node_actions[vim.o.filetype][type]
  else
    return M.node_actions["*"][type]
  end
end

M.node_actions = require("ts-node-action.filetypes")

--- @param opts? table
--- @return nil
function M.setup(opts)
  M.node_actions = vim.tbl_deep_extend("force", M.node_actions, opts or {})

  vim.api.nvim_create_user_command(
    "NodeAction",
    M.node_action,
    { desc = "Performs action on the node under the cursor." }
  )

  vim.api.nvim_create_user_command(
    "NodeActionDebug",
    M.debug,
    { desc = "Prints debug information for Ts-Node-Action Plugin" }
  )
end

local function get_node()
  if vim.treesitter.get_node then
    return vim.treesitter.get_node()
  else
    return require("nvim-treesitter.ts_utils").get_node_at_cursor()
  end
end

M.node_action = require("ts-node-action.repeat").set(function()
  local node = get_node()
  if not node then
    info("No node found at cursor")
    return
  end

  local action = find_action(node)
  if type(action) == "function" then
    do_action(action, node)
  elseif type(action) == "table" then
    if #action == 1 then
      do_action(action[1][1], node)
    else
      vim.ui.select(
        action,
        {
          prompt      = "Select Action",
          format_item = function(choice) return choice.name end
        },
        function(choice) do_action(choice[1], node) end
      )
    end
  else
    info("No action defined for '" .. vim.o.filetype .. "' node type: '" .. node:type() .. "'")
  end
end)

function M.available_actions()
  local node = get_node()
  if not node then
    info("No node found at cursor")
    return
  end

  local function format_action(tbl)
    return {
      action = function() do_action(tbl[1], node) end,
      title  = tbl.name or "Anonymous Node Action",
    }
  end

  local action = find_action(node)
  if type(action) == "function" then
    return { format_action({ action }) }
  elseif type(action) == "table" then
    return vim.tbl_map(format_action, action)
  end
end

function M.debug()
  local node = get_node()
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
        node_actions = M.node_actions,
      }
    }
  ))
end

return M
