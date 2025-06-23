local helpers = require("ts-node-action.helpers")
local actions = require("ts-node-action.actions")

local padding = {
  [","] = "%s ",
  [":"] = { "%s ", ["next_nil"] = "%s" },
  ["{"] = "%s ",
  ["=>"] = " %s ",
  ["="] = " %s ",
  ["}"] = " %s",
  ["+"] = " %s ",
  ["-"] = " %s ",
  ["*"] = " %s ",
  ["/"] = " %s ",
}

local identifier_formats =
  { "snake_case", "pascal_case", "screaming_snake_case" }

local uncollapsible = {
  ["conditional"] = true,
}

local function toggle_block(node)
  local structure = helpers.destructure_node(node)
  if type(structure.body) == "table" then
    return
  end

  local replacement

  if helpers.node_is_multiline(node) then
    if structure.parameters then
      replacement = "{ "
        .. structure.parameters
        .. " "
        .. structure.body
        .. " }"
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
  if type(structure.consequence) == "table" then
    return
  end

  local replacement = {
    structure.consequence,
    structure["if"] or structure["unless"],
    structure.condition,
  }

  return table.concat(replacement, " "),
    { cursor = { col = #structure.consequence + 1 } }
end

local function collapse_ternary(structure)
  local replacement = {
    structure.condition,
    " ? ",
    structure.consequence,
    " : ",
    structure.alternative[2],
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
    "end",
  }

  return replacement, { cursor = {}, format = true }
end

local function multiline_conditional(node)
  local structure = helpers.destructure_node(node)
  local replacement = {
    (structure["if"] or structure["unless"]) .. " " .. structure.condition,
    structure.body,
    "end",
  }

  return replacement, { cursor = {}, format = true }
end

local function toggle_hash_style(node)
  local styles = { ["=>"] = ": ", [":"] = " => " }
  local structure = helpers.destructure_node(node)

  -- Not handling non string/symbol keys
  if
    not structure.key:sub(1):match([[^"']])
    and not structure.key:sub(1):match("%a")
  then
    return
  end

  -- Fixes for symbol/string/int keys keys
  if structure[":"] and structure.key:sub(1):match("^%a") then
    structure.key = ":" .. structure.key
  elseif structure.key:sub(1, 1) == ":" then
    structure.key = structure.key:sub(2)
  end

  local replacement = structure.key
    .. styles[structure[":"] or structure["=>"]]
    .. structure.value
  local opts = {
    cursor = { col = structure[":"] and #structure.key + 1 or #structure.key },
  }

  return replacement, opts
end

local function toggle_endless_method(node)
  local structure = helpers.destructure_node(node)
  if type(structure["body"]) ~= "string" then -- multi-line methods not eligible
    return
  end

  if structure["="] then
    -- Expand to multi-line
    return { "def " .. structure["name"] .. (structure["parameters"] or ""), structure["body"], "end" }, { format = true }
  else
    -- collapse to single line
    return { "def " .. structure["name"] .. (structure["parameters"] or "") .. " = " .. structure["body"] }, { format = true }
  end
end

return {
  ["identifier"] = actions.cycle_case(identifier_formats),
  ["constant"] = actions.cycle_case(identifier_formats),
  ["binary"] = actions.toggle_operator(),
  ["array"] = actions.toggle_multiline(padding, uncollapsible),
  ["hash"] = actions.toggle_multiline(padding, uncollapsible),
  ["argument_list"] = actions.toggle_multiline(padding, uncollapsible),
  ["method_parameters"] = actions.toggle_multiline(padding, uncollapsible),
  ["integer"] = actions.toggle_int_readability(),
  ["block"] = { { toggle_block, name = "Toggle Block" } },
  ["do_block"] = { { toggle_block, name = "Toggle Block" } },
  ["if"] = { { handle_conditional, name = "Handle Conditional" } },
  ["unless"] = { { handle_conditional, name = "Handle Conditional" } },
  ["if_modifier"] = {
    { multiline_conditional, name = "Multiline Conditional" },
  },
  ["unless_modifier"] = {
    { multiline_conditional, name = "Multiline Conditional" },
  },
  ["conditional"] = { { expand_ternary, name = "Expand Ternary" } },
  ["pair"] = { { toggle_hash_style, name = "Toggle Hash Style" } },
  ["method"] = { { toggle_endless_method, name = "Toggle endless method" } }
}
