local actions = require("ts-node-action.actions")
local helpers = require("ts-node-action.helpers")

local padding = {
  [","]   = "%s ",
  ["{"]   = "%s ",
  ["}"]   = " %s",
  ["="]   = " %s ",
  ["or"]  = " %s ",
  ["and"] = " %s ",
  ["+"]   = " %s ",
  ["-"]   = " %s ",
  ["*"]   = " %s ",
  ["/"]   = " %s ",
  [".."]  = " %s ",
}

local operator_override = {
  ["=="] = "~=",
  ["~="] = "==",
}

local quote_override = {
  { "'", "'" },
  { '"', '"' },
  { '[[', ']]' },
}

local function toggle_function(node)
  local struct = helpers.destructure_node(node)
  if type(struct.body) == "table" then
    return
  end

  if helpers.node_is_multiline(node) then
    local body = struct.body and (struct.body .. " ") or ""
    return "function" .. struct.parameters .. " " .. body .. "end"
  else
    return { "function" .. struct.parameters, struct.body or "", "end" }, { format = true, cursor = {} }
  end
end

local function toggle_named_function(node)
  local struct = helpers.destructure_node(node)
  if type(struct.body) == "table" then
    return
  end

  if helpers.node_is_multiline(node) then
    return (struct["local"] and "local " or "")
        .. "function "
        .. struct.name
        .. struct.parameters .. " "
        .. struct.body .. " end"
  else
    return {
      (struct["local"] and "local " or "") .. "function " .. struct.name .. struct.parameters,
      struct.body,
      "end"
    }, { format = true, cursor = { col = struct["local"] and 6 or 0 } }
  end
end

return {
  ["table_constructor"]    = actions.toggle_multiline(padding),
  ["arguments"]            = actions.toggle_multiline(padding),
  ["binary_expression"]    = actions.toggle_operator(operator_override),
  ["string"]               = actions.cycle_quotes(quote_override),
  ["function_definition"]  = { { toggle_function, "Toggle Function" } },
  ["function_declaration"] = { { toggle_named_function, "Toggle Function" } }
}
