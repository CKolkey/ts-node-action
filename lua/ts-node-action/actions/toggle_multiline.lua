local helpers = require("ts-node-action.helpers")

local function collapse_child_nodes(padding)
  return function(node)
    local replacement = {}

    for child, _ in node:iter_children() do
      if child:named_child_count() > 0 then
        table.insert(replacement, collapse_child_nodes(padding)(child))
      else
        table.insert(replacement, helpers.padded_node_text(child, padding))
      end
    end

    return table.concat(vim.tbl_flatten(replacement))
  end
end

local function expand_child_nodes(node)
  local replacement = {}

  for child in node:iter_children() do
    if child:named() then
      table.insert(replacement, helpers.node_text(child))
    else
      if child:next_sibling() and child:prev_sibling() then
        replacement[#replacement] = replacement[#replacement] .. helpers.node_text(child)
      elseif not child:prev_sibling() then -- Opening brace
        table.insert(replacement, helpers.node_text(child))
      else -- Closing brace
        table.insert(replacement, helpers.node_text(child))
      end
    end
  end

  return replacement
end

return function(padding)
  padding = padding or {}

  local function action(node)
    local fn
    if helpers.multiline_node(node) then
      fn = expand_child_nodes
    else
      fn = collapse_child_nodes(padding)
    end
    return fn(node), { cursor = {}, format = true }
  end

  return { { action, name = "Toggle Multiline" } }
end
