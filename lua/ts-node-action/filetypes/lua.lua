local actions = require("ts-node-action.actions")

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

return {
  ["false"]             = actions.toggle_boolean(),
  ["true"]              = actions.toggle_boolean(),
  ["table_constructor"] = actions.toggle_multiline(padding),
  ["arguments"]         = actions.toggle_multiline(padding),
  ["binary_expression"] = actions.toggle_operator(operator_override),
  ["string"]            = actions.cycle_quotes(quote_override)
}
