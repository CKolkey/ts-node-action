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
  ["{"]   = "%s ",
  ["}"]   = {
    " %s",
    ["{"] = "%s",
    [","] = "%s",
    [";"] = "%s",
    ["prev_nil"] = "%s",
  },
  ["let"] = "%s ",
  ["as"]  = " %s ",
  ["in"]  = { " %s ", ["prev_nil"] = "%s ", },
  ["="]   = " %s ",
  [":"]   = "%s ",
  [";"]   = "%s ",
  [","]   = "%s ",
}
local padding_use_list = {
  ["{"]  = "%s",
  ["}"]  = "%s",
  [","]  = "%s ",
}

local uncollapsible = {
  ["string_literal"]       = true,
  ["let_declaration"]      = true,
  ["reference_type"]       = true,
  ["reference_expression"] = true,
  ["type_case_expression"] = true,
  ["macro_invocation"]     = true,
  ["macro"]                = true,
  ["for_expression"]       = true,
  ["range_expression"]     = true,
  ["line_comment"]         = true,
}

return {
  ["boolean_literal"]          = actions.toggle_boolean(),
  ["integer_literal"]          = actions.toggle_int_readability(),
  ["binary_expression"]        = actions.toggle_operator(operators),
  ["compound_assignment_expr"] = actions.toggle_operator(operators),
  ["use_list"]                 = actions.toggle_multiline(padding_use_list, uncollapsible),
  ["block"]                    = actions.toggle_multiline(padding, uncollapsible),
  ["parameters"]               = actions.toggle_multiline(padding, uncollapsible),
  ["arguments"]                = actions.toggle_multiline(padding, uncollapsible),
  ["array_expression"]         = actions.toggle_multiline(padding, uncollapsible),
  ["tuple_expression"]         = actions.toggle_multiline(padding, uncollapsible),
  ["tuple_pattern"]            = actions.toggle_multiline(padding, uncollapsible),
  ["enum_variant_list"]        = actions.toggle_multiline(padding, uncollapsible),
  ["field_initializer_list"]   = actions.toggle_multiline(padding, uncollapsible),
  ["field_declaration_list"]   = actions.toggle_multiline(padding, uncollapsible),
}
