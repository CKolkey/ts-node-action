local helpers = require("ts-node-action.helpers")
local actions = require("ts-node-action.actions")

local padding = {
  [","]  = "%s ",
  [":"]  = "%s ",
  ["{"]  = "%s ",
  ["=>"] = " %s ",
  ["="]  = " %s ",
  ["}"]  = " %s",
  ["+"]  = " %s ",
  ["-"]  = " %s ",
  ["*"]  = " %s ",
  ["/"]  = " %s ",
}

local identifier_formats = { "snake_case", "pascal_case", "screaming_snake_case" }

local function toggle_block(node)
  local structure = helpers.destructure_node(node)
  local replacement

  if helpers.node_is_multiline(node) then
    if string.find(structure.body, "\n") then
      print("(TS:Action) Cannot collapse multi-line block")
      return
    end

    if structure.parameters then
      replacement = "{ " .. structure.parameters .. " " .. structure.body .. " }"
    else
      replacement = "{ " .. structure.body .. " }"
    end
  else
    if structure.parameters then
      replacement = { "do " .. structure.parameters, structure.body, "end" }
    else
      replacement = { "do", structure.body, "end" }
    end
  end

  return replacement, { cursor = {}, format = true }
end

local function inline_conditional(structure)
  local replacement = {
    structure.consequence,
    structure["if"] or structure["unless"],
    structure.condition
  }

  return table.concat(replacement, " "), { cursor = { col = #structure.consequence + 1 } }
end

local function collapse_ternary(structure)
  local replacement = {
    structure.condition,
    " ? ",
    structure.consequence,
    " : ",
    vim.trim(string.gsub(structure.alternative, "else\n", ""))
  }

  return table.concat(replacement), { cursor = { col = #replacement[1] + 1 } }
end

local function handle_conditional(node)
  local structure = helpers.destructure_node(node)
  local fn
  if structure.alternative then
    fn = collapse_ternary
  else
    fn = inline_conditional
  end

  return fn(structure)
end

local function expand_ternary(node)
  local structure = helpers.destructure_node(node)
  local replacement = {
    "if " .. structure.condition,
    structure.consequence,
    "else",
    structure.alternative,
    "end"
  }

  return replacement, { cursor = {}, format = true }
end

local function multiline_conditional(node)
  local structure = helpers.destructure_node(node)
  local replacement = {
    (structure["if"] or structure["unless"]) .. " " .. structure.condition,
    structure.body,
    "end"
  }

  return replacement, { cursor = {}, format = true }
end

local function toggle_hash_style(node)
  local styles    = { ["=>"] = ": ", [":"] = " => " }
  local structure = helpers.destructure_node(node)

  -- Not handling non string/symbol keys
  if not structure.key:sub(1):match([[^"']]) and not structure.key:sub(1):match("%a") then
    return
  end

  -- Fixes for symbol/string/int keys keys
  if structure[":"] and structure.key:sub(1):match("^%a") then
    structure.key = ":" .. structure.key
  elseif structure.key:sub(1, 1) == ":" then
    structure.key = structure.key:sub(2)
  end

  local replacement = structure.key .. styles[structure[":"] or structure["=>"]] .. structure.value
  local opts        = { cursor = { col = structure[":"] and #structure.key + 1 or #structure.key } }

  return replacement, opts
end

return {
  ["identifier"]        = actions.cycle_case(identifier_formats),
  ["constant"]          = actions.cycle_case(identifier_formats),
  ["binary"]            = actions.toggle_operator(),
  ["array"]             = actions.toggle_multiline(padding),
  ["hash"]              = actions.toggle_multiline(padding),
  ["argument_list"]     = actions.toggle_multiline(padding),
  ["method_parameters"] = actions.toggle_multiline(padding),
  ["integer"]           = actions.toggle_int_readability(),
  ["block"]             = { { toggle_block, name = "Toggle Block" } },
  ["do_block"]          = { { toggle_block, name = "Toggle Block" } },
  ["if"]                = { { handle_conditional, name = "Handle Conditional" } },
  ["unless"]            = { { handle_conditional, name = "Handle Conditional" } },
  ["if_modifier"]       = { { multiline_conditional, name = "Multiline Conditional" } },
  ["unless_modifier"]   = { { multiline_conditional, name = "Multiline Conditional" } },
  ["conditional"]       = { { expand_ternary, name = "Expand Ternary" } },
  ["pair"]              = { { toggle_hash_style, name = "Toggle Hash Style" } },
}
