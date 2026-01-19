local M = {}

local ts = vim.treesitter

--- @private
--- @param targets TSNode[]
--- @return integer start_row
--- @return integer start_col
--- @return integer end_row
--- @return integer end_col
local function combined_range(targets)
  local start_row, start_col, end_row, end_col
  for _, target in ipairs(targets) do
    local sr, sc, er, ec = target:range()
    if start_row == nil or sr < start_row then
      start_row = sr
    end
    if start_col == nil or sc < start_col then
      start_col = sc
    end
    if end_row == nil or er > end_row then
      end_row = er
    end
    if end_col == nil or ec > end_col then
      end_col = ec
    end
  end
  return start_row, start_col, end_row, end_col
end

--- @private
--- @param targets TSNode[]
--- @return integer start_row
--- @return integer start_col
--- @return integer end_row
--- @return integer end_col
local function combined_range(targets)
  local start_row, start_col, end_row, end_col
  for _, target in ipairs(targets) do
    local sr, sc, er, ec = target:range()
    if start_row == nil or sr < start_row then
      start_row = sr
    end
    if start_col == nil or sc < start_col then
      start_col = sc
    end
    if end_row == nil or er > end_row then
      end_row = er
    end
    if end_col == nil or ec > end_col then
      end_col = ec
    end
  end
  return start_row, start_col, end_row, end_col
end

--- @private
--- @param replacement string|table
--- @param opts { cursor: { col: number, row: number }, callback: function, format: boolean, target: TSNode | TSNode[] }
--- All opts fields are optional
local function replace_node(node, replacement, opts)
  if type(replacement) ~= "table" then
    replacement = { replacement }
  end

  local start_row, start_col, end_row, end_col
  if vim.islist(opts.target) then
    start_row, start_col, end_row, end_col = combined_range(opts.target)
  else
    start_row, start_col, end_row, end_col = (opts.target or node):range()
  end
  vim.api.nvim_buf_set_text(
    vim.api.nvim_get_current_buf(),
    start_row,
    start_col,
    end_row,
    end_col,
    replacement
  )

  if opts.cursor then
    vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), {
      start_row + (opts.cursor.row or 0) + 1,
      start_col + (opts.cursor.col or 0),
    })
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
  vim.notify(
    message,
    vim.log.levels.INFO,
    { title = "Node Action", icon = " " }
  )
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

--- @param node TSNode
--- @param lang string
--- @return function|nil
local function find_action(node, lang)
  local type = node:type()
  if M.node_actions[lang] and M.node_actions[lang][type] then
    return M.node_actions[lang][type]
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

--- @private
--- @return TSNode|nil, string|nil
function M._get_node()
  -- stylua: ignore
  local parser = (vim.fn.has("nvim-0.12") == 1 and ts.get_parser())
      or (vim.fn.has("nvim-0.11") == 1 and ts.get_parser(nil, nil, { error = false }))
      or (type(ts.get_parser) == "function" and ts.get_parser(nil, nil))

  if not parser then
    return
  end

  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local range4 = { lnum - 1, col, lnum - 1, col }
  local langtree = parser:language_for_range(range4)
  local node = langtree:named_node_for_range(range4)
  return node, langtree:lang()
end

M.node_action = require("ts-node-action.repeat").set(function()
  local node, lang = M._get_node()
  if not node then
    info("No node found at cursor")
    return
  end

  local action = find_action(node, lang)
  if type(action) == "function" then
    do_action(action, node)
  elseif type(action) == "table" then
    if action.ask == false or #action == 1 then
      for _, act in ipairs(action) do
        do_action(act[1], node)
      end
    else
      vim.ui.select(action, {
        prompt = "Select Action",
        format_item = function(choice)
          return choice.name
        end,
      }, function(choice)
        do_action(choice[1], node)
      end)
    end
  else
    info(
      "No action defined for '"
        .. lang
        .. "' node type: '"
        .. node:type()
        .. "'"
    )
  end
end)

function M.available_actions()
  local node, lang = M._get_node()
  if not node then
    info("No node found at cursor")
    return
  end

  local function format_action(tbl)
    return {
      action = function()
        do_action(tbl[1], node)
      end,
      title = tbl.name or "Anonymous Node Action",
    }
  end

  local action = find_action(node, lang)
  if type(action) == "function" then
    return { format_action({ action }) }
  elseif type(action) == "table" then
    return vim.tbl_map(format_action, action)
  end
end

function M.debug()
  local node, lang = M._get_node()
  if not node then
    info("No node found at cursor")
    return
  end

  print(vim.inspect({
    node = {
      lang = lang,
      filetype = vim.o.filetype,
      node_type = node:type(),
      named = node:named(),
      named_children = node:named_child_count(),
    },
    plugin = {
      node_actions = M.node_actions,
    },
  }))
end

return M
