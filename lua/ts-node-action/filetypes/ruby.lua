local helpers = require("ts-node-action.helpers")

local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["=>"] = " %s ",
  ["="] = " %s ",
  ["}"] = " %s"
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

local function cycle_case(node)
  local text = helpers.node_text(node)
  local words
  local format

  local formats = {
    ["toSnakeCase"] = function(tbl)
      return string.lower(table.concat(tbl, "_"))
    end,

    ["toCamelCase"] = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:gsub("^.", string.upper)
      end, tbl)
      local value, _ = table.concat(tmp, ""):gsub("^.", string.lower)
      return value
    end,

    ["toPascalCase"] = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:gsub("^.", string.upper)
      end, tbl)
      local value, _ = table.concat(tmp, "")
      return value
    end,

    ["toYellingCase"] = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:upper()
      end, tbl)
      local value, _ = table.concat(tmp, "_")
      return value
    end,
  }

  if (string.find(text, "_") and string.sub(text, 1, 1) == string.sub(text, 1, 1):lower()) or text:lower() == text then -- snake_case
    words = vim.split(string.lower(text), "_", { trimempty = true })
    format = formats.toPascalCase

  elseif string.sub(text, 1, 2) == string.sub(text, 1, 2):upper() then -- YELLING_CASE
    words = vim.split(string.lower(text), "_", { trimempty = true })
    format = formats.toCamelCase

  elseif string.sub(text, 1, 1) == string.sub(text, 1, 1):upper() then -- PascalCase
    words = vim.split(
      text:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper),
      " ",
      { trimempty = true }
    )
    format = formats.toYellingCase

  else -- camelCase
    words = vim.split(
      text:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper),
      " ",
      { trimempty = true }
    )
    format = formats.toSnakeCase
  end

  helpers.replace_node(node, format(words))
end

local function toggle_block(node)
  local block_params
  local block_body = ""
  local replacement

  for child, _ in node:iter_children() do
    local text = helpers.node_text(child)
    if child:type() == "block_parameters" then
      block_params = " " .. text
    end

    if child:type() == "block_body" or child:type() == "body_statement" then
      block_body = text
    end
  end

  if helpers.multiline_node(node) then
    local start_row = node:start()
    local indent_width = string.rep(" ", vim.o.shiftwidth)
    local indent = string.rep(indent_width, vim.fn.indent(start_row + 1))

    if block_params then
      replacement = {
        "do" .. block_params,
        indent .. indent_width .. block_body,
        indent .. "end",
      }
    else
      replacement = {
        "do",
        indent .. indent_width .. block_body,
        indent .. "end",
      }
    end
  else
    if string.find(block_body, "\n") then
      print("(TS:Action) Cannot collapse multi-line block")
      return
    end

    if block_params then
      replacement = "{" .. block_params .. " " .. block_body .. " }"
    else
      replacement = "{ " .. block_body .. " }"
    end
  end

  helpers.replace_node(node, replacement, { cursor = true })
end

local function toggle_comparison(node)
  local translations = {
    ["!="] = "==",
    ["=="] = "!=",
    [">"] = "<",
    ["<"] = ">",
    [">="] = "<=",
    ["<="] = ">=",
  }

  local replacement = {}

  for child, _ in node:iter_children() do
    local text = helpers.node_text(child)
    if translations[text] then
      table.insert(replacement, translations[text])
    else
      table.insert(replacement, text)
    end
  end

  helpers.replace_node(node, table.concat(replacement, " "))
end

local function inline_conditional(node)
  local body
  local condition

  for child, _ in node:iter_children() do
    local text = helpers.node_text(child)
    if child:type() == "then" then
      body = text:gsub("^%s+", "")
    end

    if child:type() ~= "if" and child:type() ~= "then" and child:type() ~= "end" then
      condition = text
    end
  end

  helpers.replace_node(
    node,
    body .. " " .. helpers.node_text(node:child(0)) .. " " .. condition,
    { cursor = { col = #body + 1 } }
  )
end

local function collapse_ternary(node)
  local replacement = {}
  for child, _ in node:iter_children() do
    if child:type() == "call" then
      table.insert(replacement, helpers.node_text(child) .. " ? ")
    end

    if child:type() == "then" then
      table.insert(replacement, vim.trim(helpers.node_text(child)) .. " : ")
    end

    if child:type() == "else" then
      table.insert(replacement, vim.trim(helpers.node_text(child):gsub("else", "")))
    end
  end

  helpers.replace_node(node, table.concat(replacement), { cursor = { col = #replacement[1] - 2 } })
end

local function expand_ternary(node)
  local replacement = {}

  for child, _ in node:iter_children() do
    if child:type() == "call" then
      table.insert(replacement, "if " .. helpers.node_text(child))
    elseif child:named() then
      table.insert(replacement, helpers.indent_node_text(child, vim.fn.shiftwidth()))
    end
  end

  table.insert(replacement, 3, helpers.indent_text("else", node))
  table.insert(replacement, helpers.indent_text("end", node))
  helpers.replace_node(node, replacement, { cursor = true })
end

local function handle_conditional(node)
  -- If there is an 'else' clause, collapse into ternary, otherwise inline it
  if node:named_child_count() > 2 then
    collapse_ternary(node)
  else
    inline_conditional(node)
  end
end

local function multiline_conditional(node)
  local replacement = {}
  local capture_body = true
  local body
  local condition

  for child, _ in node:iter_children() do
    if child:type() == "if" or child:type() == "unless" then
      table.insert(replacement, helpers.node_text(child) .. " ")
      capture_body = false
    end

    if capture_body then
      body = helpers.indent_node_text(child)
    end

    if not capture_body then
      condition = helpers.node_text(child)
    end
  end

  replacement = { replacement[1] .. condition, "  " .. body, helpers.indent_text("end", node) }
  helpers.replace_node(node, replacement, { cursor = true })
end

return {
  ["true"] = toggle_boolean,
  ["false"] = toggle_boolean,
  ["array"] = toggle_multiline,
  ["hash"] = toggle_multiline,
  ["argument_list"] = toggle_multiline,
  ["method_parameters"] = toggle_multiline,
  ["identifier"] = cycle_case,
  ["constant"] = cycle_case,
  ["block"] = toggle_block,
  ["do_block"] = toggle_block,
  ["binary"] = toggle_comparison,
  ["if"] = handle_conditional,
  ["unless"] = handle_conditional,
  ["if_modifier"] = multiline_conditional,
  ["unless_modifier"] = multiline_conditional,
  ["conditional"] = expand_ternary,
}
