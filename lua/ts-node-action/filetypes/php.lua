local actions = require("ts-node-action.actions")

local padding = {
  [","]  = "%s ",
  ["=>"] = " %s ",
  ["="]  = " %s ",
  ["["]  = "%s",
  ["]"]  = "%s",
  ["}"]  = " %s",
  ["{"]  = "%s ",
  ["||"] = " %s ",
  ["&&"] = " %s ",
  ["."]  = " %s ",
  ["+"]  = " %s ",
  ["*"]  = " %s ",
  ["-"]  = " %s ",
  ["/"]  = " %s ",
}

local operators = {
  ["!="]  = "==",
  ["!=="] = "===",
  ["=="]  = "!=",
  ["==="] = "!==",
  [">"]   = "<",
  ["<"]   = ">",
  [">="]  = "<=",
  ["<="]  = ">=",
}

return {
  ["array_creation_expression"] = actions.toggle_multiline(padding),
  ["formal_parameters"]         = actions.toggle_multiline(padding),
  ["arguments"]                 = actions.toggle_multiline(padding),
  ["subscript_expression"]      = actions.toggle_multiline(padding),
  ["compound_statement"]        = actions.toggle_multiline(padding),
  ["name"]                      = actions.cycle_case(),
  ["encapsed_string"]           = actions.cycle_quotes(),
  ["boolean"]                   = actions.toggle_boolean(),
  ["binary_expression"]         = actions.toggle_operator(operators),
}
