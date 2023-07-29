local operators = {
  [">"] = "<",
  ["<"] = ">",
  [">="] = "<=",
  ["<="] = ">=",
  ["+"] = "-",
  ["-"] = "+",
  ["*"] = "/",
  ["/"] = "*",
  ["!="] = "==",
  ["=="] = "!=",
  ["∉"] = "∈",
  ["∈"] = "∉",
}

local boolean = {
  ["true"] = "false",
  ["false"] = "true",
}

local padding = {
  [","] = "%s ",
  [";"] = "%s ",
}

local actions = require("ts-node-action.actions")
return {
  ["identifier"] = actions.cycle_case(),
  ["boolean_literal"] = actions.toggle_boolean(boolean),
  ["integer_literal"] = actions.toggle_int_readability(),
  ["argument_list"] = actions.toggle_multiline(padding, {}),
  ["vector_expression"] = actions.toggle_multiline(padding, {}),
  ["tuple_expression"] = actions.toggle_multiline(padding, {}),
  ["operator"] = actions.toggle_operator(operators),
}
