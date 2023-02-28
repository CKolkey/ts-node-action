local helpers = require("ts-node-action.helpers")

local ERROR_NS = "TS:NodeAction:Python:CycleImport - "

---@param tables table[]
---@param key string
---@return table
local function collect_values_for_key(tables, key)
  local values = {}
  for _, tbl in ipairs(tables) do
    for _, value in ipairs(tbl[key]) do
      table.insert(values, value)
    end
  end
  return values
end

----@param import_from_statement TSNode
----@return table
local function destructure_import_from_statement(import_from_statement)
  local module   = import_from_statement:named_child(0)
  local names    = {}
  local comments = {}

  local first_sibling_row
  local sibling  = module:next_named_sibling()
  while sibling do

    if sibling:type() == "comment" then
      table.insert(comments, sibling)
    else
      if not first_sibling_row then
        first_sibling_row = sibling:start()
      end
      table.insert(names, helpers.node_text(sibling))
    end

    sibling = sibling:next_named_sibling()
  end

  local format = "single"
  if #names > 1 then
    format = first_sibling_row == module:start() and "inline" or "expand"
  elseif helpers.node_is_multiline(import_from_statement) then
    format = "expand"
  end

  return {
      type     = "import_from_statement",
      node     = import_from_statement,
      modules  = { helpers.node_text(module) },
      names    = names,
      comments = comments,
      format   = format
  }
end

---@param import_statement TSNode
---@return table
local function destructure_import_statement(import_statement)
  local modules  = {}
  local comments = {}

  for child in import_statement:iter_children() do
    if child:named() then
      if child:type() == "comment" then
        table.insert(comments, child)
      else
        table.insert(modules, helpers.node_text(child))
      end
    end
  end

  return {
      type     = "import_statement",
      node     = import_statement,
      modules  = modules,
      names    = modules,
      comments = comments,
      format   = #modules > 1 and "inline" or "single",
  }
end

---@param node TSNode
---@param func fun(node: TSNode): boolean
---@return TSNode[] in reverse order
local function get_prev_siblings_while(node, func)
  local nodes = {}
  local prev_sibling = node:prev_named_sibling()
  while prev_sibling and func(prev_sibling) do
    table.insert(nodes, prev_sibling)
    prev_sibling = prev_sibling:prev_named_sibling()
  end
  return nodes
end

---@param node TSNode
---@param func fun(node: TSNode): boolean
---@return TSNode[]
local function get_next_siblings_while(node, func)
  local nodes = {}
  local next_sibling = node:next_named_sibling()
  while next_sibling and func(next_sibling) do
    table.insert(nodes, next_sibling)
    next_sibling = next_sibling:next_named_sibling()
  end
  return nodes
end

-- Collect qualifying siblings adjacent to origin_stmt and destructure them.
---@param origin_stmt table
---@param prev_siblings TSNode[] in reverse order
---@param next_siblings TSNode[]
---@param destructure fun(node: TSNode): table
---@param of_any_format boolean
---@return table[]
local function assemble_sibling_stmts(
    origin_stmt, prev_siblings, next_siblings, destructure, of_any_format)
  local stmts = {}

  for _, node in ipairs(prev_siblings) do
    local sibling_stmt = destructure(node)
    if of_any_format or sibling_stmt.format == origin_stmt.format then
      table.insert(stmts, 1, sibling_stmt)
    else
      break
    end
  end

  table.insert(stmts, origin_stmt)

  for _, node in ipairs(next_siblings) do
    local sibling_stmt = destructure(node)
    if of_any_format or sibling_stmt.format == origin_stmt.format then
      table.insert(stmts, sibling_stmt)
    else
      break
    end
  end

  return stmts
end

local cycler_types = {
  import_statement = {
    allowed_formats = { "single", "inline",  },
    destructure = destructure_import_statement,
    make_sibling_validator = function(origin_stmt)
      return function(sibling)
        return sibling:type() == origin_stmt.type
      end
    end,
    cycle = {
      single = function(stmts, names, indent, config)
        local replacement = {}
        for i, name in ipairs(names) do
          table.insert(replacement, (i ~= 1 and indent or "") .. "import " .. name)
        end
        return replacement
      end,
      inline = function(stmts, names, indent, config)
        local replacement = {}
        local prepend     = "import "
        local line        = indent .. prepend .. table.concat(names, ", ")

        if #line > config.line_length then
          line = indent .. prepend
          for _, name in ipairs(names) do
            if #line + #name >= config.line_length then
              table.insert(replacement, line:sub(1, -3))
              line = indent .. prepend .. name .. ", "
            else
              line = line .. name .. ", "
            end
          end
          line = line:sub(1, -3)
        end
        table.insert(replacement, line)

        return replacement
      end,
    },
  },
  import_from_statement = {
    allowed_formats = { "single", "inline", "expand",  },
    destructure = destructure_import_from_statement,
    make_sibling_validator = function(origin_stmt)
      local module = origin_stmt.modules[1]
      return function(sibling)
        return sibling:type() == origin_stmt.type and
          helpers.node_text(sibling:named_child(0)) == module
      end
    end,
    cycle = {
      single = function(stmts, names, indent, config)
        local replacement = {}
        for i, name in ipairs(names) do
          table.insert(
            replacement,
            (i == 1 and "" or indent) ..
            "from " .. stmts[1].modules[1] .. " import " .. name .. ""
          )
        end
        return replacement
      end,
      inline = function(stmts, names, indent, config)
        local replacement = {}
        local prepend     = "from " .. stmts[1].modules[1] .. " import "
        local line        = indent .. prepend .. table.concat(names, ", ")
        local line_length = config.line_length
        local use_parens  = config.inline_use_parens
        local eol_length  = use_parens and 1 or 2

        if #line > line_length then
          line = indent .. (use_parens and prepend .. "(" or prepend)

          for _, name in ipairs(names) do
            if #line + #name + eol_length > line_length then
              line = use_parens and line:sub(1, -2) or line .. "\\"
              table.insert(replacement, line)
              line = indent .. "    " .. name .. ", "
            else
              line = line .. name .. ", "
            end
          end

          line = line:sub(1, -3) .. (use_parens and ")" or "")
        end
        table.insert(replacement, line)
        return replacement
      end,
      expand = function(stmts, names, indent, config)
        local replacement = {}
        local use_parens  = config.expand_use_parens
        local first_eol   = use_parens and "(" or "\\"
        local body_eol    = use_parens and "" or " \\"
        table.insert(
          replacement,
          "from " .. stmts[1].modules[1] .. " import " .. first_eol
        )
        for i, name in ipairs(names) do
          local line
          if i == #names then
            line = indent .. "    " .. name .. (use_parens and "," or "")
          else
            line = indent .. "    " .. name .. "," .. body_eol
          end
          table.insert(replacement, line)
        end
        if use_parens then
          table.insert(replacement, indent .. ")")
        end
        return replacement
      end,
    }
  },
}

-- Create a fake node to represent the replacement target. This is necessary
-- when the replacement spans multiple nodes without a suitable parent to serve
-- as a the target (eg, a top-level node's parent is the root).
--
-- Should be indistiguishable from a TSNode, other than type(target) == "table",
-- but range() is only what's necessary by init.lua:replace_node().
--
---@param first_node TSNode
---@param last_node TSNode
---@return table
local function make_target_node(first_node, last_node)
  -- TSNode's are userdata, which can't be cloned/altered, so this proxy's calls
  -- to it and overrides the position methods.
  local target = {}
  for k, _ in pairs(getmetatable(first_node)) do
    target[k] = function(_, ...)
      return first_node[k](first_node, ...)
    end
  end
  local start_pos = { first_node:start() }
  local end_pos   = { last_node:end_() }
  function target:start() return unpack(start_pos) end
  function target:end_() return unpack(end_pos) end
  function target:range()
    return start_pos[1], start_pos[2], end_pos[1], end_pos[2]
  end

  return target
end

---@param formats table
---@param format string
---@return string|nil
local function find_next_format(formats, format)
  for i, f in ipairs(formats) do
    if f == format then
      return formats[i + 1] or formats[1]
    end
  end
end

---@param node TSNode
---@param config table
---@return table|nil, table|nil
local function cycle(node, config)

  local cycler = cycler_types[node:type()]

  local stmt = cycler.destructure(node)
  if #stmt.comments > 0 then
    return
  end

  local format = find_next_format(config.formats, stmt.format)
  if not format then
    return
  end

  if not vim.tbl_contains(cycler.allowed_formats, format) then
    print(ERROR_NS .. "Format '" .. format .. "' not supported")
    return
  end

  local is_valid_sibling = cycler.make_sibling_validator(stmt)
  local stmts = assemble_sibling_stmts(
    stmt,
    get_prev_siblings_while(stmt.node, is_valid_sibling),
    get_next_siblings_while(stmt.node, is_valid_sibling),
    cycler.destructure,
    config.siblings_of_any_format
  )
  local names = collect_values_for_key(stmts, "names")

  local start  = {node:start()}
  local indent = string.rep(" ", start[2])

  local replacement = cycler.cycle[format](stmts, names, indent, config)

  return replacement, {
    target = make_target_node(
      stmts[1].node,
      stmts[#stmts].node
    ),
    cursor = {row = 0, col = 0},
    format = true,
  }
end

local default_config = {
  ---@type table[] formats to cycle through, in the order provided
  formats                = {},
  ---@type number maximum line length for inline imports
  line_length            = 80,
  ---@type boolean include siblings when format differs
  siblings_of_any_format = true,
  ---@type boolean use parens for inline imports (otherwise use \)
  inline_use_parens      = true,
  ---@type boolean use parens for expanded imports (otherwise use \)
  expand_use_parens      = true,
}

---@param config table
---@return table|nil
return function(config)
  config = vim.tbl_deep_extend('force', default_config, config or {})

  vim.validate{
    formats={ config.formats, "table" },
    line_length={ config.line_length, "number" },
    siblings_of_any_format={ config.siblings_of_any_format, "boolean" },
    inline_use_parens={ config.inline_use_parens, "boolean" },
    expand_use_parens={ config.expand_use_parens, "boolean" },
  }

  if #config.formats == 0 then
    print(ERROR_NS .. "Empty config.formats, no formats to cycle")
  end

  local function action(node)
    return cycle(node, config)
  end

  return { action, name = "Cycle Import" }
end
