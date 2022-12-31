local helpers = require("ts-node-action.helpers")

local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["=>"] = " %s ",
  ["="] = " %s ",
  ["}"] = " %s",
  ["+"] = " %s ",
  ["-"] = " %s ",
  ["*"] = " %s ",
  ["/"] = " %s ",
}

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

  return replacement, { cursor = {} }
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

  local replacement = body .. " " .. helpers.node_text(node:child(0)) .. " " .. condition
  return replacement, { cursor = { col = #body + 1 } }
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

  return table.concat(replacement), { cursor = { col = #replacement[1] - 2 } }
end

local function handle_conditional(node)
  local fn
  if node:named_child_count() > 2 then
    fn = collapse_ternary
  else
    fn = inline_conditional
  end

  return fn(node)
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
  return replacement, { cursor = {} }
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
  return replacement, { cursor = {} }
end

local function toggle_hash_style(node)
  local replacement = {}
  local toggle = { ["=>"] = ": ", [":"] = " => " }

  for child, _ in node:iter_children() do
    local text = helpers.node_text(child)
    if child:type() == "=>" or child:type() == ":" then
      table.insert(replacement, toggle[text])
    else
      table.insert(replacement, text)
    end
  end

  return table.concat(replacement)
end

local toggle_boolean   = require("ts-node-action.actions.toggle_boolean")
local toggle_multiline = require("ts-node-action.actions.toggle_multiline")(padding)
local cycle_case       = require("ts-node-action.actions.cycle_case")
local toggle_operator  = require("ts-node-action.actions.toggle_operator")

return {
  ["true"]              = toggle_boolean,
  ["false"]             = toggle_boolean,
  ["array"]             = toggle_multiline,
  ["hash"]              = toggle_multiline,
  ["argument_list"]     = toggle_multiline,
  ["method_parameters"] = toggle_multiline,
  ["identifier"]        = cycle_case,
  ["constant"]          = cycle_case,
  ["block"]             = toggle_block,
  ["do_block"]          = toggle_block,
  ["binary"]            = toggle_operator,
  ["if"]                = handle_conditional,
  ["unless"]            = handle_conditional,
  ["if_modifier"]       = multiline_conditional,
  ["unless_modifier"]   = multiline_conditional,
  ["conditional"]       = expand_ternary,
  ["pair"]              = toggle_hash_style,
}
