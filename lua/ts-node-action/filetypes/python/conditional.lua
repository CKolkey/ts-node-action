local helpers = require("ts-node-action.helpers")
local pyhelpers = require("ts-node-action.filetypes.python.helpers")

local M = {}

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

local function parenthesize_if_needed(node, text)
  if node_types_to_parenthesize[node:type()] and text:sub(1, 1) ~= "(" then
    return "(" .. text .. ")"
  end

  return text
end

-- Helper that returns the text of the left and right hand sides of a
-- statement. For example, the left hand side of:
--
--  - `return 1`      is `return` and the right hand side is `1`.
--  - `x = 1`         is `x = `   and the right hand side is `1`.
--  - `x = y = z = 1` is `x = y = z = ` and the right hand side is `1`.
--  - `print(3)`      is ""       and the right hand side is `print(3)`.
--
---@param node TSNode
---@param collapse function
---@return string|nil, string|nil, string|nil, TSNode|nil
local function node_text_lhs_rhs(node, collapse)
  local lhs      = nil
  local rhs      = nil
  local type     = node:type()
  local child    = node:named_child(0)

  if type == "return_statement" then
    lhs = "return "
    rhs = collapse(child)
  elseif type == "expression_statement" then
    type = child:type()
    lhs  = ""

    if type == "assignment" then
      local identifiers = {}
      -- handle multiple assignments, eg: x = y = z = 1
      while child:type() == "assignment" do
        table.insert(identifiers, helpers.node_text(child:named_child(0)))
        child = child:named_child(1)
      end
      lhs = table.concat(identifiers, " = ") .. " = "
      rhs = collapse(child)
    elseif type == "call" then
      local identifier = helpers.node_text(child:named_child(0))
      child            = child:named_child(1)
      rhs              = identifier .. collapse(child)
    elseif type == "boolean_operator" or
        type == "parenthesized_expression" then
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
---@param parent TSNode
---@param parent_type string
---@param start_row number
---@return TSNode|nil, string|nil
local function find_row_parent(parent, parent_type, start_row)

  while parent ~= nil and
      parent_type ~= "if_statement" and
      parent_type ~= "for_statement" do
    parent = parent:parent()
    if parent == nil then
      return
    end
    parent_type = parent:type()
    if select(1, parent:start()) ~= start_row then
      return
    end
  end

  if parent_type == "if_statement" or parent_type == "for_statement" then
    return parent, parent_type
  end
end

-- We detect if it's safe to expand an inline if/else surrounded by parens
-- and remove them by skipping to it's parent, because the parent is
-- replaced by this action, with the expanded if/else.
--
-- Cases considered safe:
-- `x = (conditional_expression)`
-- `return (conditional_expression)`
--
---@param parent TSNode
---@param parent_type string
---@return TSNode, string
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

---@param node TSNode
---@param comments table
---@return nil (mutates comments)
local function deep_collect_comments(node, comments)
  for child in node:iter_children() do
    if child:named() then
      if child:type() == "comment" then
        table.insert(comments, child)
      else
        deep_collect_comments(child, comments)
      end
    end
  end
end

---@param parent TSNode
---@param children table
---@param comments table
---@return nil (mutates children and comments)
local function collect_named_children(parent, children, comments)
  for child in parent:iter_children() do
    if child:named() then
      if child:type() == "comment" then
        table.insert(comments, child)
      else
        table.insert(children, child)
        deep_collect_comments(child, comments)
      end
    end
  end
end

---@param if_statement TSNode
---@return table
M.destructure_if_statement = function(if_statement)
  local condition
  local consequence = {}
  local alternative = {}
  local comments    = {}

  for child in if_statement:iter_children() do
    if child:named() then
      local child_type = child:type()

      if child_type == "comment" then
        table.insert(comments, child)
      elseif child_type == "block" then
        collect_named_children(child, consequence, comments)
      elseif child_type == "else_clause" then
        local block = {}
        collect_named_children(child, block, comments)
        collect_named_children(block[1], alternative, comments)
      else
        condition = child
      end

    end
  end

  return {
    node        = if_statement,
    condition   = condition,
    consequence = consequence,
    alternative = alternative,
    comments    = comments
  }
end

---@param node TSNode
---@return table
M.destructure_conditional_expression = function(node)
  local comments = {}
  local children = {}

  collect_named_children(node, children, comments)

  return {
    node        = node,
    condition   = children[2],
    consequence = { children[1] }, -- as a table for consistency
    alternative = { children[3] }, -- which allows for sharing
    comments    = comments,
  }
end

---@param stmt table
---@param collapse function
---@return table|nil, table|nil
M.expand_cond_expr = function(stmt, collapse)
  local parent      = stmt.node:parent()
  local parent_type = parent:type()

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
    parent = stmt.node
  else
    -- parent context is not yet supported, eg: y = 3 or (4 if x > 0 else 5)
    return
  end

  local start_row, start_col = parent:start()
  local row_parent           = find_row_parent(parent, parent_type, start_row)
  local cursor               = {}
  -- when we are embedded on the end of an inlined if/for statement, we need
  -- to expand on to the next line and shift the cursor/indent
  local if_indent            = ""
  local else_indent          = ""
  if row_parent then
    local _, row_start_col = row_parent:start()
    -- cursor position is relative to the node being replaced (parent)
    cursor                 = { row = 1, col = row_start_col - start_col + 4 }
    if_indent              = string.rep(" ", row_start_col + 4)
    else_indent            = if_indent
  else
    else_indent = string.rep(" ", start_col)
  end
  local body_indent = else_indent .. string.rep(" ", 4)

  local replacement = {
    if_indent .. "if " .. collapse(stmt.condition) .. ":",
    body_indent .. lhs .. collapse(stmt.consequence[1]),
  }

  if #stmt.alternative > 0 then
    table.insert(replacement, else_indent .. "else:")
    table.insert(
      replacement,
      body_indent .. lhs .. collapse(stmt.alternative[1])
    )
  end

  local callback = nil
  if row_parent then
    table.insert(replacement, 1, "")
    callback = function() pyhelpers.node_trim_whitespace(parent) end
  end

  return replacement, {
    cursor   = cursor,
    callback = callback,
    format   = true,
    target   = parent,
  }
end

--- @param stmt table { node, condition, consequence, alternative, comments }
--- @param collapse function
--- @return table|nil, table|nil
M.inline_if = function(stmt, collapse)

  local lhs, rhs, _, child = node_text_lhs_rhs(
    stmt.consequence[1],
    collapse
  )
  if lhs == nil then
    return
  end
  rhs = parenthesize_if_needed(child, rhs)

  local cond_text = collapse(stmt.condition)

  local replacement = { "if " .. cond_text .. ": " .. lhs .. rhs }
  return replacement, { cursor = {} }
end

--- @param cons_type string
--- @param alt_type string
--- @param cons_lhs string
--- @param alt_lhs string
--- @return boolean
local function body_types_are_inlineable(cons_type, alt_type, cons_lhs, alt_lhs)
  -- strict match
  if cons_type == "assignment" or alt_type == "assignment" then
    return cons_type == alt_type and cons_lhs == alt_lhs
  elseif cons_type == "return_statement" or alt_type == "return_statement" then
    return cons_type == alt_type
  end
  -- these do not depend on a common lhs and can freely appear on either side
  local mixable_match_body_types = {
    ["call"]                     = true,
    ["boolean_operator"]         = true,
    ["parenthesized_expression"] = true,
  }
  return mixable_match_body_types[cons_type] and
      mixable_match_body_types[alt_type]
end

--- @param stmt table { node, condition, consequence, alternative, comments }
--- @param collapse function
--- @return string|nil, table|nil
M.inline_ifelse = function(stmt, collapse)

  local cons_lhs, cons_rhs, cons_type, cons_child = node_text_lhs_rhs(
    stmt.consequence[1],
    collapse
  )
  if cons_lhs == nil then
    return
  end
  cons_rhs = parenthesize_if_needed(cons_child, cons_rhs)

  local alt_lhs, alt_rhs, alt_type, alt_child = node_text_lhs_rhs(
    stmt.alternative[1],
    collapse
  )
  if alt_rhs == nil or not body_types_are_inlineable(cons_type, alt_type, cons_lhs, alt_lhs) then
    return
  end

  alt_rhs = parenthesize_if_needed(alt_child, alt_rhs)

  local cond_text = collapse(stmt.condition)

  local replacement = cons_lhs .. cons_rhs ..
      " if " .. cond_text ..
      " else " .. alt_rhs

  return replacement, {
    cursor = { col = string.len(cons_lhs .. cons_rhs) + 1 },
  }
end

return M
