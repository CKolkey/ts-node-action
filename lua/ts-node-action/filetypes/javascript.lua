local actions = require("ts-node-action.actions")

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

local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
}

return {
  ["property_identifier"] = actions.cycle_case(),
  ["string_fragment"]     = actions.conceal_string(),
  ["binary_expression"]   = actions.toggle_operator(operators),
  ["object"]              = actions.toggle_multiline(padding),
  ["array"]               = actions.toggle_multiline(padding),
  ["statement_block"]     = actions.toggle_multiline(padding),
  ["object_pattern"]      = actions.toggle_multiline(padding),
  ["object_type"]         = actions.toggle_multiline(padding),
  ["formal_parameters"]   = actions.toggle_multiline(padding),
  ["argument_list"]       = actions.toggle_multiline(padding),
  ["method_parameters"]   = actions.toggle_multiline(padding),
  ["number"]              = actions.toggle_int_readability(),
}
