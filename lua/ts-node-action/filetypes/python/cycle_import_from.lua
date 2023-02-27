local helpers = require("ts-node-action.helpers")

--- @param import_from_statement TSNode
--- @return table
local function destructure_import_from_statement(import_from_statement)
  local module   = import_from_statement:named_child(0)
  local names    = {}
  local sibling  = module:next_named_sibling()
  local comments = {}

  while sibling do
    if sibling:type() == "comment" then
      table.insert(comments, sibling)
    else
      table.insert(names, helpers.node_text(sibling))
    end
    sibling = sibling:next_named_sibling()
  end

  local format
  if helpers.node_is_multiline(import_from_statement) then
    format = "block"
  elseif #names > 1 then
    format = "inline"
  else
    format = "single"
  end

  return {
      node     = import_from_statement,
      module   = helpers.node_text(module),
      names    = names,
      comments = comments,
      format   = format,
  }
end

-- Find direct sibling import_from_statements that import from the same module
-- as the origin statement.
-- @param origin_stmt table
local function find_sibling_imports(origin_stmt)
  local stmts = {}
  local names = {}

  local prev_sibling = origin_stmt.node:prev_named_sibling()
  while prev_sibling do
    if (prev_sibling:type() == "import_from_statement" and
        helpers.node_text(prev_sibling:named_child(0)) == origin_stmt.module)
    then
      local stmt = destructure_import_from_statement(prev_sibling)
      table.insert(stmts, 1, stmt)
      prev_sibling = prev_sibling:prev_named_sibling()
    else
      prev_sibling = nil
    end
  end

  for _, stmt in ipairs(stmts) do
    for _, name in ipairs(stmt.names) do table.insert(names, name) end
  end

  table.insert(stmts, origin_stmt)
  for _, name in ipairs(origin_stmt.names) do table.insert(names, name) end

  local next_sibling = origin_stmt.node:next_named_sibling()
  while next_sibling do
    if (next_sibling:type() == "import_from_statement" and
        helpers.node_text(next_sibling:named_child(0)) == origin_stmt.module)
    then
      local stmt = destructure_import_from_statement(next_sibling)
      table.insert(stmts, stmt)
      for _, name in ipairs(stmt.names) do table.insert(names, name) end
      next_sibling = next_sibling:next_named_sibling()
    else
      next_sibling = nil
    end
  end

  return stmts, names
end

-- Create a stub node to represent the replacement target.
-- This is necessary because the replacement spans multiple
-- top-level nodes and so we can't target the first and last
-- nodes directly.
local function create_stub_target_node(stmts)
  local start_row, start_col     = stmts[1].node:start()
  local _, _, last_row, last_col = stmts[#stmts].node:range()
  local node = {}
  function node.range(self)
      return start_row, start_col, last_row, last_col
  end
  return node
end

-- @param origin_stmt table
-- @param new_format string
-- @return table, table
local function cycle(origin_stmt, new_format)
  local replacement  = {}
  local stmts, names = find_sibling_imports(origin_stmt)

  if new_format == "single" then
    for _, name in ipairs(names) do
      table.insert(
        replacement,
        "from " .. origin_stmt.module .. " import " .. name .. ""
      )
    end
  elseif new_format == "inline" then
    table.insert(
      replacement,
      "from " .. origin_stmt.module ..
      " import " .. table.concat(names, ", ")
    )
  elseif new_format == "block" then
    table.insert(
      replacement,
      "from " .. origin_stmt.module .. " import ("
    )
    for _, name in ipairs(names) do
      table.insert(replacement, "    " .. name .. ",")
    end
    table.insert(replacement, ")")
  end

  return replacement, {
    target = create_stub_target_node(stmts),
    cursor = {row = 0, col = 0},
  }
end

return {
  destructure = destructure_import_from_statement,
  cycle       = cycle,
}
