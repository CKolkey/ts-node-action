local helpers = require("ts-node-action.helpers")

local function collapse_child_nodes(padding)
  return function(node)
    local replacement = {}

    for child, _ in node:iter_children() do
      if child:named_child_count() > 0 then -- Node is a container
        local child_text = collapse_child_nodes(padding)(child)
        if not child_text then return end -- We found a comment, abort

        table.insert(replacement, child_text)
      elseif child:extra() then -- Bail if there are Comments
        return
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
    if helpers.node_is_multiline(node) then
      fn = collapse_child_nodes(padding)
    else
      fn = expand_child_nodes
    end
    return fn(node), { cursor = {}, format = true }
  end

  return { { action, name = "Toggle Multiline" } }
end
