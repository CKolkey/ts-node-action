local actions = require("ts-node-action.actions")
local helpers = require("ts-node-action.helpers")

local M = {}

---@param node TSNode
M.node_trim_whitespace = function(node)
  local start_row, _, end_row, _ = node:range()
  vim.cmd("silent! keeppatterns " .. (start_row + 1) .. "," .. (end_row + 1) .. "s/\\s\\+$//g")
end

-- Recreating actions.toggle_multiline.collapse_child_nodes() here because
-- it is not exported.
--
---@param padding table
---@param uncollapsible table
---@return function
M.collapse_child_nodes = function(padding, uncollapsible)

  ---@param node TSNode
  ---@return string
  local function action(node)
    if not helpers.node_is_multiline(node) then
      return helpers.node_text(node)
    end

    local tbl = actions.toggle_multiline(padding, uncollapsible)
    local replacement = tbl[1][1](node)

    return replacement
  end

  return action
end

return M
