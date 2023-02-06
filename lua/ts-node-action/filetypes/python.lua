local helpers = require("ts-node-action.helpers")
local actions = require("ts-node-action.actions")


-- When inlined, these nodes must be parenthesized to avoid changing the
-- meaning of the code and to avoid syntax errors.
-- eg: x = lambda y: y + 1 if y else 0
--     x = (lambda y: y + 1) if y else 0
-- Both are valid, but the first is not equivalent to the second.
-- Unlike the second, the first can not be expanded to:
--    if y:
--        x = lambda y: y + 1
--    else:
--        x = 0
-- because the if/else is part of the lambda expression.
-- private
local node_types_to_parenthesize = {
  ["conditional_expression"] = true,
  ["lambda"] = true,
}

-- Helper that returns the text of the left and right hand sides of a
-- statement. For example, the left hand side of:
--
--  - `return 1` is `return` and the right hand side is `1`.
--  - `x = 1` is `x = ` and the right hand side is `1`.
--  - `x = y = z = 1` is `x = y = z = ` and the right hand side is `1`.
--
-- private
-- @param node tsnode
-- @return string, string|nil
local function node_text_lhs_rhs(node)
  local lhs = nil
  local rhs = nil

  if node:type() == "return_statement" then
    lhs = "return "
    rhs = helpers.node_text(node:named_child(0))
  elseif node:type() == "expression_statement" then
    local child = node:named_child(0)
    local identifiers = {}

    if child:type() == "assignment" then
      -- handle multiple assignments, eg: x = y = z = 1
      while child:type() == "assignment" do
        table.insert(identifiers, helpers.node_text(child:named_child(0)))
        child = child:named_child(1)
      end

      lhs = table.concat(identifiers, " = ") .. " = "
      rhs = helpers.node_text(child)
    elseif child:type() == "call" then
      lhs = helpers.node_text(child:named_child(0))
      rhs = helpers.node_text(child:named_child(1))
    end
  end

  return lhs, rhs
end

-- private
-- @param node tsnode
-- @param child_types table
-- @return boolean
local function has_descendent_of_type(node, child_types)

  for i = 0, node:named_child_count() - 1 do
    local child = node:named_child(i)

    if child_types[child:type()] then
      return true
    end

    if has_descendent_of_type(child, child_types) then
      return true
    end
  end

  return false
end

-- private
-- @param if_statement tsnode
-- @return string, table, tsnode
-- @return nil
local function inline_if(if_statement)
  local condition   = if_statement:named_child(0)
  local consequence = if_statement:named_child(1):named_child(0)
  local lhs, rhs    = node_text_lhs_rhs(consequence)

  if lhs == nil then
    return
  elseif has_descendent_of_type(consequence, node_types_to_parenthesize) and
    rhs:sub(1, 1) ~= "(" then
    rhs = "(" .. rhs .. ")"
  end

  local parent_type = if_statement:parent():type()
  local replacement
  local cursor = {}

  if parent_type == "block" or parent_type == "module" then
    replacement = {
      "if " .. helpers.node_text(condition) .. ": " .. lhs .. rhs
    }
  else
    replacement = {
      lhs .. rhs .. " if " .. helpers.node_text(condition) .. " else None"
    }
    cursor["col"] = string.len(lhs .. rhs) + 1
  end

  return replacement, { cursor = cursor, format = true }
end

-- private
-- @param if_statement tsnode
-- @return string, table, tsnode
-- @return nil
local function inline_ifelse(if_statement)
  local condition   = if_statement:named_child(0)
  local consequence = if_statement:named_child(1):named_child(0)
  local alternative = if_statement:named_child(2):named_child(0):named_child(0)

  local lhs, cons_text = node_text_lhs_rhs(consequence)
  if lhs == nil then
    return
  elseif has_descendent_of_type(consequence, node_types_to_parenthesize) and
    cons_text:sub(1, 1) ~= "(" then
    cons_text = "(" .. cons_text .. ")"
  end

  local lhs2, alt_text = node_text_lhs_rhs(alternative)
  if lhs ~= lhs2 or alt_text == nil then
    return
  elseif has_descendent_of_type(alternative, node_types_to_parenthesize) and
    alt_text:sub(1, 1) ~= "(" then
    alt_text = "(" .. alt_text .. ")"
  end

  local replacement = {
    lhs .. cons_text ..
    " if " .. helpers.node_text(condition) ..
    " else " .. alt_text
  }
  local cursor_col = string.len(lhs .. cons_text) + 1

  return replacement, { cursor = { col = cursor_col }, format = true }
end

-- The if/conditional_expression that we are expanding can find itself on
-- the same row as an inlined for or if statement.
-- For example:
--
-- `for x in range(10): x = 1 if x > 5 else x + 1`
-- `if x > 0: x = 1 if x > 5 else x + 1`
--
-- Contrived, hopefully, but this handles it, by detecting if there is a
-- for/if statement on the same row as our current parent.
--
-- private
-- @param parent tsnode
-- @param parent_type string
-- @param start_row number
-- @return tsnode, string
-- @return nil
local function find_real_row_parent(parent, parent_type, start_row)

  while parent ~= nil and
    parent_type ~= "if_statement" and
    parent_type ~= "for_statement" do
    parent      = parent:parent()
    parent_type = parent:type()
    if select(1, parent:start()) ~= start_row then
      return nil
    end
  end

  if parent_type == "if_statement" or parent_type == "for_statement" then
    return parent, parent_type
  end

  return nil
end

-- public
-- @param if_statement tsnode
-- @return string, table, tsnode
-- @return nil
local function expand_if(conditional_expression)
  local parent      = conditional_expression:parent()
  local parent_type = parent:type()
  local lhs
  local cond_order = {1, 0, 2}

  -- We detect if it's safe to expand an inline if/else surrounded by parens
  -- and remove them by skipping to it's parent, because the parent is
  -- replaced by this action, with the expanded if/else.
  if parent_type == "parenthesized_expression" then
    local paren_parent      = parent:parent()
    local paren_parent_type = paren_parent:type()
    if paren_parent_type == "return_statement" or
       paren_parent_type == "assignment" then
      parent      = paren_parent
      parent_type = paren_parent_type
    end
  end

  if parent_type == "return_statement" then
    lhs = "return "
  elseif parent_type == "assignment" then
    local identifiers = {}

    -- handle multiple assignments, eg: x = y = z = 1
    while parent:type() == "assignment" do
      table.insert(identifiers, 1, helpers.node_text(parent:named_child(0)))
      parent = parent:parent()
    end

    lhs = table.concat(identifiers, " = ") .. " = "
  elseif parent_type == "expression_statement" then
    lhs = ""
  elseif parent_type == "block" or parent_type == "module" then
    lhs = ""
    parent = conditional_expression
    cond_order = {0, 1, 2}
  else
    return
  end

  local condition    = conditional_expression:named_child(cond_order[1])
  local consequence  = conditional_expression:named_child(cond_order[2])
  local alternative  = conditional_expression:named_child(cond_order[3])
  local start_row, start_col = parent:start()
  local row_parent = find_real_row_parent(parent, parent_type, start_row)
  local cursor = {}
  -- if we are embedded after an inlined if/for statement, we need to expand
  -- to the next line and adjust the cursor/indent accordingly
  if row_parent then
    local _, row_start_col = row_parent:start()
    -- cursor position is relative to the node being replaced (parent)
    cursor = { row = 1, col = row_start_col - start_col + 4  }
    start_col = row_start_col + 4
  end
  local ifelse_indent = string.rep(" ", start_col)
  local body_indent   = ifelse_indent .. string.rep(" ", 4)

  local replacement   = {
    ifelse_indent .. "if " .. helpers.node_text(condition) .. ":",
    body_indent .. lhs .. helpers.node_text(consequence),
  }
  if row_parent then
    table.insert(replacement, 1, "")
  end

  if alternative and
    (alternative:type() ~= "none" or parent_type ~= "expression_statement") then
    table.insert(replacement, ifelse_indent .. "else:")
    table.insert(
      replacement,
      body_indent .. lhs .. helpers.node_text(alternative)
    )
  elseif parent_type == "expression_statement" then
    table.insert(replacement, ifelse_indent .. "else:")
    table.insert(replacement, body_indent .. lhs .. " None")
  end

  return replacement, {
    cursor = cursor,
    format = true,
    whitespace = {},
  }, parent
end

-- public
-- @param conditional_expression tsnode
-- @return string, table, tsnode
local function inline_if_stmt(if_statement)
  if helpers.multiline_node(if_statement) == false then
    if if_statement:named_child_count() == 3 then
      return inline_ifelse(if_statement)
    elseif if_statement:named_child_count() == 2 then
      return inline_if(if_statement)
    end
  else
    return expand_if(if_statement)
  end
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
  ["conditional_expression"]   = { { expand_if, name = "Expand Conditional" } },
  ["if_statement"]             = { { inline_if_stmt, name = "Inline Conditional" } },
}
