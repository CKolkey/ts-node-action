local actions = require("ts-node-action.actions")

local operators = {
  ["!="] = "==",
  ["=="] = "!=",
  [">"] = "<",
  ["<"] = ">",
  [">="] = "<=",
  ["<="] = ">=",
  ["-"] = "+",
  ["+"] = "-",
  ["*"] = "/",
  ["/"] = "*",
  ["+="] = "-=",
  ["-="] = "+=",
  ["++"] = "--",
  ["--"] = "++",
  ["||"] = "&&",
  ["&&"] = "||",
}

local modifiers = {
  ["public"] = "private",
  ["private"] = "public",
  ["struct"] = "class",
  ["class"] = "struct",
}

return {
  ["boolean_literal"] = actions.toggle_boolean(),
  ["binary"] = actions.toggle_operator(operators),
  ["modifier"] = actions.toggle_operator(modifiers),
  ["struct_declaration"] = actions.toggle_operator(modifiers),
  ["class_declaration"] = actions.toggle_operator(modifiers),
  ["binary_expression"] = actions.toggle_operator(operators),
  ["assignment_operator"] = actions.toggle_operator(operators),
  ["postfix_unary_expression"] = actions.toggle_operator(operators),
  ["integer_literal"] = actions.toggle_int_readability(),
}
