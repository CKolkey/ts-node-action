local actions      = require("ts-node-action.actions")
local helpers      = require("ts-node-action.helpers")
local nu           = require("ts-node-action.filetypes.python.node_utils")
local conditional  = require("ts-node-action.filetypes.python.conditional")
local cycle_import = require("ts-node-action.filetypes.python.cycle_import")

-- Special cases:
-- Because "is" and "not" are valid by themselves, they are seen as separate
-- nodes by TS.  This means that without special handling, a config of:
-- {
--   ["is"]  = " %s ",
--   ["not"] = " %s "
-- }
-- would be padded as ` is  not `.  To avoid this, we can make them smarter by
-- defining a padding rule for the case of when "not" is seen after "is".
--
-- There is also the identical case of "not in". However, "-" is both a
-- unary and binary operator.  When it is used as a binary operator, it is
-- a normal case.  For unary, we don't want any padding, and generally (always?)
-- it is preceded by a named node.  When padding, we see these as
-- prev_text=nil, so we can use that to detect the unary case with a special
-- key "prev_nil", to represent it.
local padding = {
  [","]      = "%s ",
  [":"]      = "%s ",
  ["{"]      = "%s",
  ["}"]      = "%s",
  ["for"]    = " %s ",
  ["if"]     = " %s ",
  ["else"]   = " %s ",
  ["and"]    = " %s ",
  ["or"]     = " %s ",
  ["is"]     = " %s ",
  ["not"]    = { " %s ", ["is"] = "%s " },
  ["in"]     = { " %s ", ["not"] = "%s " },
  ["=="]     = " %s ",
  ["!="]     = " %s ",
  [">="]     = " %s ",
  ["<="]     = " %s ",
  [">"]      = " %s ",
  ["<"]      = " %s ",
  ["+"]      = " %s ",
  ["-"]      = { " %s ", ["prev_nil"] = "%s", },
  ["*"]      = " %s ",
  ["/"]      = " %s ",
  ["//"]     = " %s ",
  ["%"]      = " %s ",
  ["**"]     = " %s ",
  ["lambda"] = " %s ",
  ["with"]   = " %s ",
  ["as"]     = " %s ",
  ["import"] = " %s ",
  ["from"]   = "%s ",
}

local uncollapsible = {}

local boolean_override = {
  ["True"]  = "False",
  ["False"] = "True",
}

---@param padding_override table
---@param uncollapsible_override table
---@return table
local function inline_if_statement(padding_override, uncollapsible_override)
  padding_override = vim.tbl_deep_extend(
    'force', padding, padding_override or {}
  )
  uncollapsible_override = vim.tbl_deep_extend(
    'force', uncollapsible, uncollapsible_override or {}
  )
  local collapse = nu.collapse_func(
    padding_override,
    uncollapsible_override
  )

  local function action(if_statement)
    local stmt = conditional.destructure_if_statement(if_statement)
    -- we can't inline multiple statements within a block
    if #stmt.consequence > 1 or #stmt.alternative > 1 then
      return
    end

    if #stmt.comments > 0 then
      return
    end

    if helpers.node_is_multiline(if_statement) then
      local fn
      if #stmt.alternative ~= 0 then
        fn = conditional.inline_ifelse
      else
        fn = conditional.inline_if
      end
      return fn(stmt, collapse)
    else
      -- an if_statement of the form `if True: print(1)`
      -- and this knows how to expand it
      return conditional.expand_cond_expr(stmt, collapse)
    end

  end

  return { action, name = "Inline Conditional" }
end

---@param padding_override table
---@param uncollapsible_override table
---@return table
local function expand_conditional_expression(
  padding_override, uncollapsible_override
)
  padding_override = vim.tbl_deep_extend(
    'force', padding, padding_override or {}
  )
  uncollapsible_override = vim.tbl_deep_extend(
    'force', uncollapsible, uncollapsible_override or {}
  )
  local collapse = nu.collapse_func(
    padding_override,
    uncollapsible_override
  )

  local function action(conditional_expression)
    local stmt = conditional.destructure_conditional_expression(
      conditional_expression
    )
    if #stmt.comments > 0 then return end

    return conditional.expand_cond_expr(stmt, collapse)
  end

  return { action, name = "Expand Conditional" }
end

-- see python/cycle_import.lua for more config options
local cycle_import_from_config = {
  ---@type string[] list of formats to cycle through; uses the provided order
  formats = { "single", "inline", "expand" },
  ---@type number maximum line length for inline imports
  line_length            = 80,
  ---@type boolean include siblings when format differs
  siblings_of_any_format = true,
  ---@type boolean use parens for inline imports (otherwise use \)
  inline_use_parens      = true,
  ---@type boolean use parens for expanded imports (otherwise use \)
  expand_use_parens      = true,
}

local cycle_import_config = {
  ---@type string[] list of formats to cycle through; uses the provided order
  formats = { "single", "inline" },
  ---@type number maximum line length for inline imports
  line_length            = 80,
  ---@type boolean include siblings when format differs
  siblings_of_any_format = true,
}

return {
  ["dictionary"]               = actions.toggle_multiline(padding, uncollapsible),
  ["set"]                      = actions.toggle_multiline(padding, uncollapsible),
  ["list"]                     = actions.toggle_multiline(padding, uncollapsible),
  ["tuple"]                    = actions.toggle_multiline(padding, uncollapsible),
  ["argument_list"]            = actions.toggle_multiline(padding, uncollapsible),
  ["parameters"]               = actions.toggle_multiline(padding, uncollapsible),
  ["list_comprehension"]       = actions.toggle_multiline(padding, uncollapsible),
  ["set_comprehension"]        = actions.toggle_multiline(padding, uncollapsible),
  ["dictionary_comprehension"] = actions.toggle_multiline(padding, uncollapsible),
  ["generator_expression"]     = actions.toggle_multiline(padding, uncollapsible),
  ["true"]                     = actions.toggle_boolean(boolean_override),
  ["false"]                    = actions.toggle_boolean(boolean_override),
  ["comparison_operator"]      = actions.toggle_operator(),
  ["integer"]                  = actions.toggle_int_readability(),
  ["conditional_expression"]   = { expand_conditional_expression(padding, uncollapsible), },
  ["if_statement"]             = { inline_if_statement(padding, uncollapsible), },
  ["import_from_statement"]    = { cycle_import(cycle_import_from_config), },
  ["import_statement"]         = { cycle_import(cycle_import_config), },
}
