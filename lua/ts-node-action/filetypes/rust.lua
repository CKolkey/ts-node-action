local actions = require("ts-node-action.actions")

local operators = {
  -- assignment
  ["+="] = "-=",
  ["-="] = "+=",
  ["%="] = "/=",
  ["/="] = "%=",
  -- bitwise assignment
  ["&="] = "|=",
  ["|="] = "^=",
  ["^="] = "&=",
  -- comparison
  ["!="] = "==",
  ["=="] = "!=",
  [">"]  = "<",
  ["<"]  = ">",
  [">="] = "<=",
  ["<="] = ">=",
  -- shift
  ["<<"] = ">>",
  [">>"] = "<<",
  -- shift assignment
  [">>="] = "<<=",
  ["<<="] = ">>=",
  -- arithmetic
  ["+"] = "-",
  ["-"] = "+",
  ["*"] = "/",
  ["/"] = "*",
  -- bitwise
  ["|"] = "&",
  ["&"] = "|",
  -- logical
  ["||"] = "&&",
  ["&&"] = "||",
}

local padding = {
  ["{"]  = "%s ",
  ["}"]  = {
    " %s",
    ["{"] = "%s",
    [","] = "%s",
    [";"] = "%s",
    ["prev_nil"] = "%s",
  },
  ["as"] = " %s ",
  ["in"] = { " %s ", ["prev_nil"] = "%s ", },
  [":"]  = "%s ",
  [";"]  = "%s ",
  [","]  = "%s ",
}
local padding_compact = {
  ["{"]  = "%s",
  ["}"]  = "%s",
  [","]  = "%s ",
}

local uncollapsible = {
  ["string_literal"]   = true,
  ["macro_invocation"] = true,
  ["macro"]            = true,
  ["for_expression"]   = true,
  ["range_expression"] = true,
  ["line_comment"]     = true,
}

return {
  ["boolean_literal"]          = actions.toggle_boolean(),
  ["integer_literal"]          = actions.toggle_int_readability(),
  ["binary_expression"]        = actions.toggle_operator(operators),
  ["compound_assignment_expr"] = actions.toggle_operator(operators),
  ["arguments"]                = actions.toggle_multiline(padding, uncollapsible),
  ["parameters"]               = actions.toggle_multiline(padding, uncollapsible),
  ["block"]                    = actions.toggle_multiline(padding, uncollapsible),
  ["use_list"]                 = actions.toggle_multiline(padding_compact, uncollapsible),
  ["array_expression"]         = actions.toggle_multiline(padding, uncollapsible),
  ["tuple_expression"]         = actions.toggle_multiline(padding, uncollapsible),
  ["tuple_pattern"]            = actions.toggle_multiline(padding, uncollapsible),
  ["field_initializer_list"]   = actions.toggle_multiline(padding, uncollapsible),
  ["field_declaration_list"]   = actions.toggle_multiline(padding, uncollapsible),
  ["enum_variant_list"]        = actions.toggle_multiline(padding, uncollapsible),
}
