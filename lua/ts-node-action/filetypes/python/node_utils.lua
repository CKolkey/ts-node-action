local actions = require("ts-node-action.actions")
local helpers = require("ts-node-action.helpers")

-- WARN: Functions defined here should be treated as private/internal.
-- This is like an incubator and all are subject to change.

-- NOTE: All functions are for TSNode, so rather than prefixing every function
-- name with "node_", the module is named "node_utils".

local M = {}

M.lines = function(node)
  local lines = helpers.node_text(node)
  if type(lines) == "string" then
    return { lines }
  end
  return lines
end

---@param node TSNode
M.trim_whitespace = function(node)
  local start_row, _, end_row, _ = node:range()
  vim.cmd("silent! keeppatterns " .. (start_row + 1) .. "," .. (end_row + 1) .. "s/\\s\\+$//g")
end

-- Recreating actions.toggle_multiline.collapse_child_nodes() here because
-- it is not exported.
--
---@param padding table
---@param uncollapsible table
---@return function @A function that takes a TSNode and returns a string
M.collapse_func = function(padding, uncollapsible)
  local collapse = actions.toggle_multiline(padding, uncollapsible)[1][1]

  return function(node)
    if not helpers.node_is_multiline(node) then
      return helpers.node_text(node)
    end
    return collapse(node)
  end
end

-- Like vim.tbl_filter, but for TSNodes.
--
---@param accept fun(node: TSNode): boolean @returns true for a valid node
---@param iter fun(): TSNode|nil @returns the next node
---@return TSNode[]
M.filter = function(accept, iter)
  local nodes = {}
  local node  = iter()
  while node and accept(node) do
    table.insert(nodes, node)
    node = iter()
  end
  return nodes
end

-- Like filter, but stops at the first falsey value.
--
---@param accept fun(node: TSNode): boolean @returns true for a valid node
---@param iter fun(): TSNode|nil @returns the next node
---@return TSNode[]
M.takewhile = function(accept, iter)
  local nodes = {}
  local node  = iter()
  while node and accept(node) do
    table.insert(nodes, node)
    node = iter()
  end
  return nodes
end

M.iter_named_children = function(node)
  local iter = node:iter_children()
  return function()
    local child = iter()
    while child and not child:named() do
      child = iter()
    end
    return child
  end
end
M.iter_prev_named_sibling = function(node)
  local sibling = node:prev_named_sibling()
  return function()
    if sibling then
      local curr_sibling = sibling
      sibling = sibling:prev_named_sibling()
      return curr_sibling
    end
  end
end
M.iter_next_named_sibling = function(node)
  local sibling = node:next_named_sibling()
  return function()
    if sibling then
      local curr_sibling = sibling
      sibling = sibling:next_named_sibling()
      return curr_sibling
    end
  end
end
M.iter_parent = function(node)
  local parent = node:parent()
  return function()
    if parent then
      local curr_parent = parent
      parent = parent:parent()
      return curr_parent
    end
  end
end


-- Create a fake node to represent the replacement target. This is necessary
-- when the replacement spans multiple nodes without a suitable parent to serve
-- as a the target (eg, a top-level node's parent is the root and we are acting
-- on multiple children).
--
-- This is indistiguishable from a TSNode, other than type(target) == "table".
--
---@param node TSNode
---@param start_pos table
---@param end_pos table
---@return table
M.make_target = function(node, start_pos, end_pos)
  -- TSNode's are userdata, which can't be cloned/altered, so this proxy's calls
  -- to it and overrides the position methods.
  local target = {}
  for k, _ in pairs(getmetatable(node)) do
    target[k] = function(_, ...)
      return node[k](node, ...)
    end
  end
  function target:start() return unpack(start_pos) end
  function target:end_() return unpack(end_pos) end
  function target:range()
    return start_pos[1], start_pos[2], end_pos[1], end_pos[2]
  end

  return target
end

return M
