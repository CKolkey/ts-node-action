local helpers = require("ts-node-action.helpers")

local padding = {
  [","] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
  ["="] = " %s ",
}

local function toggle_boolean(node)
  helpers.replace_node(node, tostring(node:type() ~= "true"))
end

local function collapse_child_nodes(node)
  local replacement = {}

  for child, _ in node:iter_children() do
    if child:named_child_count() > 0 then
      table.insert(replacement, collapse_child_nodes(child))
    else
      table.insert(replacement, helpers.padded_node_text(child, padding))
    end
  end

  return table.concat(vim.tbl_flatten(replacement))
end

local function expand_child_nodes(node)
  local replacement = {}

  for child in node:iter_children() do
    if child:named() then
      table.insert(replacement, helpers.indent_node_text(child, vim.fn.shiftwidth()))
    else
      if child:next_sibling() and child:prev_sibling() then
        replacement[#replacement] = replacement[#replacement] .. helpers.node_text(child)
      elseif not child:prev_sibling() then -- Opening brace
        table.insert(replacement, helpers.node_text(child))
      else -- Closing brace
        table.insert(replacement, helpers.indent_node_text(child))
      end
    end
  end

  return replacement
end

local function toggle_multiline(node)
  local fn
  if helpers.multiline_node(node) then
    fn = expand_child_nodes
  else
    fn = collapse_child_nodes
  end

  helpers.replace_node(node, fn(node), { cursor = true })
end

return {
  ["table_constructor"] = toggle_multiline,
  ["arguments"] = toggle_multiline,
  ["true"] = toggle_boolean,
  ["false"] = toggle_boolean,
}
