local helpers = require("ts-node-action.helpers")
local actions = require("ts-node-action.actions")
local txt     = function(val) return helpers.node_text(val) end

-- private
-- @param block tsnode
-- @return string, string|nil
local function block_text_lhs_rhs(block)
  local lhs
  local rhs
  if block:type() == "return_statement" then
    lhs = "return "
    rhs = txt(block:named_child(0))
  elseif block:type() == "expression_statement" and
         block:named_child(0):type() == "assignment" then
    local assignment = block:named_child(0)
    local identifier = assignment:named_child(0)
    lhs = txt(identifier) .. " = "
    rhs = txt(assignment:named_child(1))
  else
    return nil
  end
  return lhs, rhs
end

local function inline_if(if_statement)
  local condition   = if_statement:named_child(0)
  local consequence = if_statement:named_child(1):named_child(0)
  local lhs, rhs = block_text_lhs_rhs(consequence)
  if lhs == nil then
    return
  end
  local replacement = {
    lhs .. rhs .. " if " .. txt(condition) .. " else None"
  }
  local cursor_col = string.len(lhs .. rhs) + 1
  return replacement, { cursor = { col = cursor_col }, format = true }
end

local function inline_ifelse(if_statement)
  local condition   = if_statement:named_child(0)
  local consequence = if_statement:named_child(1):named_child(0)
  local alternative = if_statement:named_child(2):named_child(0):named_child(0)
  local lhs, conseq_text = block_text_lhs_rhs(consequence)
  if lhs == nil then
    return
  end
  local lhs2, alter_text = block_text_lhs_rhs(alternative)
  if lhs ~= lhs2 or alter_text == nil then
    return
  end
  local replacement = {
    lhs .. conseq_text .. " if " .. txt(condition) .. " else " .. alter_text
  }
  local cursor_col = string.len(lhs .. conseq_text) + 1
  return replacement, { cursor = { col = cursor_col }, format = true }
end

local function inline_if_stmt(if_statement)
  if if_statement:named_child_count() == 3 then
    return inline_ifelse(if_statement)
  elseif if_statement:named_child_count() == 2 then
    return inline_if(if_statement)
  end
end

local function expand_if(conditional_expression)
  local parent       = conditional_expression:parent()
  local parent_type  = parent:type()
  local _, start_col = parent:start()
  local lhs
  if parent_type == "return_statement" then
    lhs = "return "
  elseif parent_type == "assignment" then
    lhs = txt(parent:named_child(0)) .. " = "
  else
    return
  end
  local condition   = conditional_expression:named_child(1)
  local consequence = conditional_expression:named_child(0)
  local alternative = conditional_expression:named_child(2)
  local else_indent = string.rep(" ", start_col)
  local body_indent = else_indent .. string.rep(" ", 4)
  local replacement = {
    "if " .. txt(condition) .. ":",
    body_indent .. lhs .. txt(consequence),
    else_indent .. "else:",
    body_indent .. lhs .. txt(alternative),
  }
  return replacement, { cursor = {}, format = true }, parent
end

-- Special cases:
-- Because "is" and "not" are valid by themselves, they are seen as separate
-- unnamed nodes by TS.  This means that without special handling, a config of:
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
-- key "nil", to represent it.
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
  ["not"]    = { [""] = " %s ", ["is"]  = "%s " },
  ["in"]     = { [""] = " %s ", ["not"] = "%s " },
  ["=="]     = " %s ",
  ["!="]     = " %s ",
  [">="]     = " %s ",
  ["<="]     = " %s ",
  [">"]      = " %s ",
  ["<"]      = " %s ",
  ["+"]      = " %s ",
  ["-"]      = { [""] = " %s ", ["nil"] = "%s", },
  ["*"]      = " %s ",
  ["/"]      = " %s ",
  ["//"]     = " %s ",
  ["%"]      = " %s ",
  ["**"]     = " %s ",
  ["lambda"] = " %s ",
  ["with"]   = " %s ",
  ["as"]     = " %s ",
}

local boolean_override = {
  ["True"]  = "False",
  ["False"] = "True",
}

return {
  ["dictionary"]               = actions.toggle_multiline(padding),
  ["set"]                      = actions.toggle_multiline(padding),
  ["list"]                     = actions.toggle_multiline(padding),
  ["tuple"]                    = actions.toggle_multiline(padding),
  ["argument_list"]            = actions.toggle_multiline(padding),
  ["parameters"]               = actions.toggle_multiline(padding),
  ["list_comprehension"]       = actions.toggle_multiline(padding),
  ["set_comprehension"]        = actions.toggle_multiline(padding),
  ["dictionary_comprehension"] = actions.toggle_multiline(padding),
  ["generator_expression"]     = actions.toggle_multiline(padding),
  ["true"]                     = actions.toggle_boolean(boolean_override),
  ["false"]                    = actions.toggle_boolean(boolean_override),
  ["comparison_operator"]      = actions.toggle_operator(),
  ["conditional_expression"]   = { { expand_if, name = "Expand If Stmt" } },
  ["if_statement"]             = { { inline_if_stmt, name = "Inline If Stmt" } },
}
