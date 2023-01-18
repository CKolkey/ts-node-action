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

return {
  ["field_declaration_list"] = actions.toggle_multiline(padding),
  ["parameters"]             = actions.toggle_multiline(padding),
  ["enum_variant_list"]      = actions.toggle_multiline(padding),
  ["block"]                  = actions.toggle_multiline(padding),
  ["array_expression"]       = actions.toggle_multiline(padding),
  ["tuple_expression"]       = actions.toggle_multiline(padding),
  ["tuple_pattern"]          = actions.toggle_multiline(padding),
  ["boolean_literal"]        = actions.toggle_boolean(),
}
