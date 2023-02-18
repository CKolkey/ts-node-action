local helpers = require("ts-node-action.helpers")
local actions = require("ts-node-action.actions")

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
  ["import"] = " %s ",
  ["from"]   = "%s ",
}

local boolean_override = {
  ["True"]  = "False",
  ["False"] = "True",
}


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
-- because "1 if y else 0" is inside the lambda.
local node_types_to_parenthesize = {
  ["conditional_expression"] = true,
  ["boolean_operator"] = true,
  ["lambda"] = true,
}

local function parenthesize_if_necessary(node, text)
  if node_types_to_parenthesize[node:type()] and
    text:sub(1, 1) ~= "(" then
    return "(" .. text .. ")"
  end
  return text
end

-- Recreating actions.toggle_multiline.collapse_child_nodes() here because
-- it is not exported.  It was not possible to use helpers.node_text() on a
-- multiline node because it will include the "\n", which is invalid for the
-- replacement text.
--
-- @param padding_override table
-- @return function
local function collapse_child_nodes(padding_override)

  -- @param node tsnode
  -- @return string
  local function action(node)
    if not helpers.node_is_multiline(node) then
      return helpers.node_text(node)
    end
    local tbl = actions.toggle_multiline(padding_override)
    local replacement = tbl[1][1](node)
    return replacement
  end

  return action
end

-- Helper that returns the text of the left and right hand sides of a
-- statement. For example, the left hand side of:
--
--  - `return 1` is `return` and the right hand side is `1`.
--  - `x = 1` is `x = ` and the right hand side is `1`.
--  - `x = y = z = 1` is `x = y = z = ` and the right hand side is `1`.
--  - `print(3)` is `print` and the right hand side is `(3)`.
--
-- @param node tsnode
-- @return string|nil, string|nil, string
local function node_text_lhs_rhs(node, padding_override)
  local lhs   = nil
  local rhs   = nil
  local type  = node:type()
  local child = node:named_child(0)
  local collapse = collapse_child_nodes(padding_override)

  if type == "return_statement" then
    lhs = "return "
    rhs = collapse(child)

  elseif type == "expression_statement" then
    local identifiers = {}
    type = child:type()

    if type == "assignment" then
      -- handle multiple assignments, eg: x = y = z = 1
      while child:type() == "assignment" do
        table.insert(identifiers, collapse(child:named_child(0)))
        child = child:named_child(1)
      end

      lhs = table.concat(identifiers, " = ") .. " = "
      rhs = collapse(child)
    elseif type == "call" then
      lhs   = collapse(child:named_child(0))
      child = child:named_child(1)
      rhs   = collapse(child)
    elseif type == "boolean_operator" or
           type == "parenthesized_expression" then
      lhs = ""
      rhs = collapse(child)
    end
  end

  return lhs, rhs, type, child
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
-- @param parent tsnode
-- @param parent_type string
-- @param start_row number
-- @return tsnode, string
-- @return nil
local function find_real_row_parent(parent, parent_type, start_row)

  while parent ~= nil and
    parent_type ~= "if_statement" and
    parent_type ~= "for_statement" do
    parent = parent:parent()
    if parent == nil then
      return nil
    end
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

-- We detect if it's safe to expand an inline if/else surrounded by parens
-- and remove them by skipping to it's parent, because the parent is
-- replaced by this action, with the expanded if/else.
--
-- Cases considered safe:
-- `x = (conditional_expression)`
-- `return (conditional_expression)`
--
-- @param parent tsnode
-- @param parent_type string
-- @return tsnode, string
local function skip_parens_by_reparenting(parent, parent_type)
  if parent_type == "parenthesized_expression" then
    local paren_parent      = parent:parent()
    local paren_parent_type = paren_parent:type()
    if paren_parent_type == "assignment" or
      paren_parent_type == "return_statement" then
      parent      = paren_parent
      parent_type = paren_parent_type
    end
  end
  return parent, parent_type
end

-- @param if_statement tsnode
-- @return string, table, tsnode
-- @return nil
local function expand_if(conditional_expression, padding_override)
  local parent      = conditional_expression:parent()
  local parent_type = parent:type()
  local cond_order  = {1, 0, 2}

  parent, parent_type = skip_parens_by_reparenting(parent, parent_type)

  local lhs
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

  local condition   = conditional_expression:named_child(cond_order[1])
  local consequence = conditional_expression:named_child(cond_order[2])
  local alternative = conditional_expression:named_child(cond_order[3])
  local start_row, start_col = parent:start()
  local row_parent = find_real_row_parent(parent, parent_type, start_row)
  local cursor = {}
  -- when we are embedded on the end of an inlined if/for statement, we need
  -- to expand on to the next line and shift the cursor/indent
  local if_indent   = ""
  local else_indent = ""
  if row_parent then
    local _, row_start_col = row_parent:start()
    -- cursor position is relative to the node being replaced (parent)
    cursor      = { row = 1, col = row_start_col - start_col + 4  }
    if_indent   = string.rep(" ", row_start_col + 4)
    else_indent = if_indent
  else
    else_indent = string.rep(" ", start_col)
  end
  local body_indent = else_indent .. string.rep(" ", 4)

  local collapse    = collapse_child_nodes(padding_override)
  local replacement = {
    if_indent .. "if " .. collapse(condition) .. ":",
    body_indent .. lhs .. collapse(consequence),
  }

  if alternative then
    table.insert(replacement, else_indent .. "else:")
    table.insert(replacement, body_indent .. lhs .. collapse(alternative))
  end

  if row_parent then
    table.insert(replacement, 1, "")
  end

  return replacement, {
    cursor = cursor,
    strip_whitespace = {},
    format = true,
  }, parent
end

local function expand_if_expr(padding_override)
  padding_override = padding_override or padding

  -- @param conditional_expression tsnode
  -- @return string, table, tsnode
  local function action(conditional_expression)
    return expand_if(conditional_expression, padding_override)
  end

  return action
end

-- @param if_statement tsnode
-- @param padding_override table
-- @return string, table, tsnode
-- @return nil
local function inline_if(if_statement, padding_override)
  local condition = if_statement:named_child(0)
  local cons_expr = if_statement:named_child(1):named_child(0)
  -- we can't inline multiple statements
  if cons_expr:next_named_sibling() then
    return
  end

  local lhs, rhs, _, child = node_text_lhs_rhs(cons_expr, padding_override)
  if lhs == nil then
    return
  end
  rhs = parenthesize_if_necessary(child, rhs)

  local cond_text = collapse_child_nodes(padding_override)(condition)
  local replacement = { "if " .. cond_text .. ": " .. lhs .. rhs }
  return replacement, { cursor = {} }
end

-- @param cons_type string
-- @param alt_type string
-- @param cons_lhs string
-- @param alt_lhs string
-- @return boolean
local function body_types_are_inlineable(cons_type, alt_type, cons_lhs, alt_lhs)
  -- strict match
  if cons_type == "assignment" or alt_type == "assignment" then
    return cons_type == alt_type and cons_lhs == alt_lhs
  elseif cons_type == "return_statement" or alt_type == "return_statement" then
    return cons_type == alt_type
  end
  -- these do not depend on a common lhs and can be freely mixed
  local mixable_match_body_types = {
    ["call"]                     = true,
    ["boolean_operator"]         = true,
    ["parenthesized_expression"] = true,
  }
  return mixable_match_body_types[cons_type] and
         mixable_match_body_types[alt_type]
end

-- @param if_statement tsnode
-- @param padding_override table
-- @return string, table, tsnode
-- @return nil
local function inline_ifelse(if_statement, padding_override)
  local condition = if_statement:named_child(0)
  local cons_expr = if_statement:named_child(1):named_child(0)
  local alt_expr  = if_statement:named_child(2):named_child(0):named_child(0)
  -- we can't inline multiple statements
  if cons_expr:next_named_sibling() or alt_expr:next_named_sibling() then
    return
  end

  local cons_lhs, cons_rhs, cons_type, cons_child = node_text_lhs_rhs(
    cons_expr,
    padding_override
  )
  if cons_lhs == nil then
    return
  end
  cons_rhs = parenthesize_if_necessary(cons_child, cons_rhs)

  local alt_lhs, alt_rhs, alt_type, alt_child = node_text_lhs_rhs(
    alt_expr,
    padding_override
  )
  if alt_rhs == nil or
    not body_types_are_inlineable(cons_type, alt_type, cons_lhs, alt_lhs) then
    return
  end
  alt_rhs = parenthesize_if_necessary(alt_child, alt_rhs)

  local cond_text = collapse_child_nodes(padding_override)(condition)

  local replacement = cons_lhs .. cons_rhs .. " if " .. cond_text .. " else "
  if alt_type == "assignment" or alt_type == "return_statement" then
    replacement = replacement .. alt_rhs
  else
    replacement = replacement .. alt_lhs .. alt_rhs
  end

  return replacement, {
    cursor = { col = string.len(cons_lhs .. cons_rhs) + 1 },
  }
end

-- @param padding_override table
-- @return function
local function inline_if_stmt(padding_override)
  padding_override = padding_override or padding

  -- @param if_statement tsnode
  -- @return string, table, tsnode
  local function action(if_statement)
    if helpers.node_is_multiline(if_statement) then
      local fn
      if if_statement:named_child_count() == 3 then
        fn = inline_ifelse
      elseif if_statement:named_child_count() == 2 then
        fn = inline_if
      end
      return fn(if_statement, padding_override)
    else
      -- an if_statement of the form `if True: print(1)`
      -- and this knows how to expand it
      return expand_if(if_statement, padding_override)
    end
  end

  return action
end

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
  ["integer"]                  = actions.toggle_int_readability(),
  ["conditional_expression"]   = { { expand_if_expr(padding), name = "Expand Conditional" } },
  ["if_statement"]             = { { inline_if_stmt(padding), name = "Inline Conditional" } },
}
