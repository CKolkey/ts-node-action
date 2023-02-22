local helpers = require("ts-node-action.helpers")

local function collapse_child_nodes(padding)
  padding = padding or {}

  local function collapse(node)
    local replacement = {}
    local child_text
    local context

    for child, _ in node:iter_children() do
      if child:named_child_count() > 0 then
        child_text = collapse(child)
        if child_text == nil then
          return
        end
        table.insert(replacement, child_text)
        context = nil
      elseif child:type() == "comment" then
        return
      else
        context = helpers.padded_node_text(child, padding, context)
        table.insert(replacement, context)
      end
    end

    return table.concat(vim.tbl_flatten(replacement))
  end

  return collapse
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
