--- @param node TSNode
--- @return string
local get_node_text = function(node)
  return vim.treesitter.get_node_text(node, 0)
end

--- @param node TSNode
--- @param name string
--- @return TSNode
local get_field = function(node, name)
  local fields = node:field(name)
  if #fields ~= 1 then
    error(string.format("not exactly one field with name='%s'", name))
  end
  return fields[1]
end

--- @param node TSNode
--- @return string?
--- @return TSNode?
local get_assignment = function(node)
  if node:type() ~= "assignment" then
    return
  end
  return get_node_text(get_field(node, "left")), get_field(node, "right")
end

--- @param node TSNode
--- @return string?
local get_new_type = function(node)
  if node:type() == "list" and node:named_child_count() == 0 then
    return "list"
  elseif (
    node:type() == "call"
    and get_node_text(get_field(node, "function")) == "set"
    and get_field(node, "arguments"):child_count() == 2)
  then
    return "set"
  elseif node:type() == "dictionary" and node:named_child_count() == 0 then
    return "dictionary"
  end
end

--- @param node TSNode
--- @return TSNode?
local get_single_node_body = function(node)
  if node:child_count() ~= 1 then
    return
  end
  return node:child(0):child(0)
end

--- @param name string
--- @param node TSNode
--- @return string?
local get_dict_key_pair = function(name, node)
  if node:type() ~= "assignment" then
    return
  end
  local left = get_field(node, "left")
  if left:type() ~= "subscript" then
    return
  end
  if name ~= get_node_text(get_field(left, "value")) then
    return
  end
  return string.format("%s: %s", get_node_text(get_field(left, "subscript")), get_node_text(get_field(node, "right")))
end

--- @param append string
--- @param name string
--- @param node TSNode
--- @return string?
local get_append_to_value = function(append, name, node)
  if node:type() ~= "call" then
    return
  end
  local func = get_field(node, "function")
  if func:named_child_count() == 0 then
    return
  end
  if name ~= get_node_text(get_field(func, "object")) then
    return
  end
  if get_node_text(get_field(func, "attribute")) ~= append then
    return
  end
  return get_node_text(get_field(node, "arguments"):named_child(0))
end

--- @param typ string
--- @param name string
--- @param node TSNode
--- @return string?
local get_body = function(typ, name, node)
  if typ == "list" then
    return get_append_to_value("append", name, node)
  elseif typ == "set" then
    return get_append_to_value("add", name, node)
  elseif typ == "dictionary" then
    return get_dict_key_pair(name, node)
  end
end

--- @param opts {new: string, make_for_body: fun(name: string, body: TSNode): string}
--- @return fun(node: TSNode): string[]?, table?
local comprehension = function(opts)
  return function(node)
    local parent = node:parent()
    local name = get_assignment(parent)
    if not name then
      return
    end
    -- TODO support if there are more or if clauses
    if node:named_child_count() > 2 then
      return
    end
    local for_clause = get_node_text(node:named_child(1))
    local for_body = opts.make_for_body(name, get_field(node, "body"))
    return vim.split(string.format("%s = %s\n%s:\n%s", name, opts.new, for_clause, for_body), "\n"), {
      format = true,
      target = parent,
      cursor = {row = 1, col = 0},
    }
  end
end

return {
  expand_list_comprehension = comprehension({
    new = "[]",
    make_for_body = function(name, body) return string.format("%s.append(%s)", name, get_node_text(body)) end,
  }),
  expand_set_comprehension = comprehension({
    new = "set()",
    make_for_body = function(name, body) return string.format("%s.add(%s)", name, get_node_text(body)) end,
  }),
  expand_dictionary_comprehension = comprehension({
    new = "{}",
    make_for_body = function(name, body) return string.format(
      "%s[%s] = %s",
      name,
      get_node_text(get_field(body, "key")),
      get_node_text(get_field(body, "value"))
    ) end,
  }),
  inline_for_statement = function(node)
    local previous = node:prev_sibling():child(0)
    -- TODO support nested loops, look up until assignment
    if previous:type() ~= "assignment" then
      return
    end
    local name, value = get_assignment(previous)
    if not name then
      return
    end
    local typ = get_new_type(value)
    if not typ then
      return
    end
    local for_variable = get_node_text(get_field(node, "left"))
    local for_range = get_node_text(get_field(node, "right"))
    local statement = get_single_node_body(get_field(node, "body"))
    if not statement then
      return
    end
    local body = get_body(typ, name, statement)
    if not body then
      return
    end
    local templates = {
      list = "%s = [%s for %s in %s]",
      set = "%s = {%s for %s in %s}",
      dictionary = "%s = {%s for %s in %s}"
    }
    return vim.split(string.format(templates[typ], name, body, for_variable, for_range), "\n"), {
      format = true,
      cursor = {row = 0, col = #name + 3},
      target = {previous, node},
    }
  end,
}
