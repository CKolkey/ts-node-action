local M = {}

local ts_utils  = require("nvim-treesitter.ts_utils")
local ts_indent = require("nvim-treesitter.indent")

-- BEGIN Helpers

-- Returns node text as a string
local function node_text(node)
  return vim.treesitter.query.get_node_text(node, 0)
end

-- left-pad text with spaces
local function indent_text(text, indent)
  return (" "):rep(indent) .. text
end

-- Combine node_text() and indent_text(). Offset can be used to add extra padding
local function indent_node_text(node, offset)
  offset = offset or 0

  local start_row, _, _, _ = node:range()
  local indent = vim.fn.indent(start_row + 1)

  return indent_text(node_text(node), indent + offset)
end

-- Adds whitespace to some unnamed nodes for nicer formatting
local function padded_node_text(node)
  local text = node_text(node)
  if text == "," or text == ":" or text == "{" then
    text = text .. " "
  elseif text == "=>" or text == "=" then
    text = " " .. text .. " "
  elseif text == "}" then
    text = " " .. text
  end

  return text
end

-- END helpers

local function toggle_boolean(node)
  local start_row, start_col, end_row, end_col = node:range()
  local replacement = { tostring(node:type() ~= "true") }
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, replacement)
end

local function collapse_child_nodes(node)
  local replacement = {}

  for child, _ in node:iter_children() do
    if child:named_child_count() > 0 then
      table.insert(replacement, collapse_child_nodes(child))
    else
      table.insert(replacement, padded_node_text(child))
    end
  end

  return { table.concat(vim.tbl_flatten(replacement)) }
end

local function expand_child_nodes(node)
  local replacement = {}

  for child in node:iter_children() do
    if child:named() then
      table.insert(replacement, indent_node_text(child, vim.fn.shiftwidth()))
    else
      if child:next_sibling() and child:prev_sibling() then
        replacement[#replacement] = replacement[#replacement] .. node_text(child)
      elseif not child:prev_sibling() then -- Opening brace
        table.insert(replacement, node_text(child))
      else -- Closing brace
        table.insert(replacement, indent_node_text(child))
      end
    end
  end

  return replacement
end

local function toggle_multiline(node)
  local start_row, start_col, end_row, end_col = node:range()
  local fn

  if start_row == end_row then
    fn = expand_child_nodes
  else
    fn = collapse_child_nodes
  end

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, fn(node))
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

local function cycle_case(node)
  local start_row, start_col, end_row, end_col = node:range()
  local text = node_text(node)
  local words
  local format

  local formats = {
    ["toSnakeCase"] = function(tbl)
      return string.lower(table.concat(tbl, "_"))
    end,

    ["toCamelCase"] = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:gsub("^.", string.upper)
      end, tbl)
      local value, _ = table.concat(tmp, ""):gsub("^.", string.lower)
      return value
    end,

    ["toPascalCase"] = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:gsub("^.", string.upper)
      end, tbl)
      local value, _ = table.concat(tmp, "")
      return value
    end,

    ["toYellingCase"] = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:upper()
      end, tbl)
      local value, _ = table.concat(tmp, "_")
      return value
    end,
  }

  if (string.find(text, "_") and string.sub(text, 1, 1) == string.sub(text, 1, 1):lower()) or text:lower() == text then -- snake_case
    words = vim.split(string.lower(text), "_", { trimempty = true })
    format = formats.toPascalCase

  elseif string.sub(text, 1, 2) == string.sub(text, 1, 2):upper() then -- YELLING_CASE
    words = vim.split(string.lower(text), "_", { trimempty = true })
    format = formats.toCamelCase

  elseif string.sub(text, 1, 1) == string.sub(text, 1, 1):upper() then -- PascalCase
    words = vim.split(
      text:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper),
      " ",
      { trimempty = true }
    )
    format = formats.toYellingCase

  else -- camelCase
    words = vim.split(
      text:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper),
      " ",
      { trimempty = true }
    )
    format = formats.toSnakeCase
  end

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { format(words) })
end

local function toggle_block(node)
  local start_row, start_col, end_row, end_col = node:range()

  local block_params
  local block_body = ""
  local replacement

  for child, _ in node:iter_children() do
    local text = node_text(child)
    if child:type() == "block_parameters" then
      block_params = " " .. text
    end

    if child:type() == "block_body" or child:type() == "body_statement" then
      block_body = text
    end
  end

  if start_row == end_row then
    local indent_width = string.rep(" ", vim.o.shiftwidth)
    local indent = string.rep(indent_width, ts_indent.get_indent(start_row + 1))

    if block_params then
      replacement = {
        "do" .. block_params,
        indent .. indent_width .. block_body,
        indent .. "end",
      }
    else
      replacement = {
        "do",
        indent .. indent_width .. block_body,
        indent .. "end",
      }
    end
  else
    if string.find(block_body, "\n") then
      print("(TS:Action) Cannot collapse multi-line block")
      return
    end

    if block_params then
      replacement = { "{" .. block_params .. " " .. block_body .. " }" }
    else
      replacement = { "{ " .. block_body .. " }" }
    end
  end

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, replacement)
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

local function toggle_comparison(node)
  local start_row, start_col, end_row, end_col = node:range()

  local translations = {
    ["!="] = "==",
    ["=="] = "!=",
    [">"] = "<",
    ["<"] = ">",
    [">="] = "<=",
    ["<="] = ">=",
  }

  local replacement = {}

  for child, _ in node:iter_children() do
    local text = node_text(child)
    if translations[text] then
      table.insert(replacement, translations[text])
    else
      table.insert(replacement, text)
    end
  end

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { table.concat(replacement, " ") })
end

local function inline_conditional(node)
  local start_row, start_col, end_row, end_col = node:range()

  local body
  local condition

  for child, _ in node:iter_children() do
    local text = node_text(child)
    if child:type() == "then" then
      body = text:gsub("^%s+", "")
    end

    if child:type() ~= "if" and child:type() ~= "then" and child:type() ~= "end" then
      condition = text
    end
  end

  local replacement = { body .. " " .. node_text(node:child(0)) .. " " .. condition }

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, replacement)
  vim.api.nvim_win_set_cursor(0, { start_row + 1, #body + 1 + start_col })
end

local function collapse_ternary(node)
  local start_row, start_col, end_row, end_col = node:range()
  local replacement = {}

  for child, _ in node:iter_children() do
    if child:type() == "call" then
      table.insert(replacement, node_text(child) .. " ? ")
    end

    if child:type() == "then" then
      table.insert(replacement, vim.trim(node_text(child)) .. " : ")
    end

    if child:type() == "else" then
      table.insert(replacement, vim.trim(node_text(child):gsub("else", "")))
    end
  end

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { table.concat(replacement) })
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col + #replacement[1] - 2 })
end

local function expand_ternary(node)
  local start_row, start_col, end_row, end_col = node:range()
  local replacement = {}

  for child, _ in node:iter_children() do
    if child:type() == "call" then
      table.insert(replacement, "if " .. node_text(child))
    elseif child:named() then
      table.insert(replacement, indent_node_text(child, vim.fn.shiftwidth()))
    end
  end

  table.insert(replacement, 3, indent_text("else", start_col))
  table.insert(replacement, indent_text("end", start_col))

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, replacement)
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

-- If there is an 'else' clause, collapse into ternary, otherwise inline it
local function handle_conditional(node)
  if node:named_child_count() > 2 then
    collapse_ternary(node)
  else
    inline_conditional(node)
  end
end

local function multiline_conditional(node)
  local start_row, start_col, end_row, end_col = node:range()

  local replacement = {}
  local capture_body = true
  local body
  local condition

  for child, _ in node:iter_children() do
    if child:type() == "if" or child:type() == "unless" then
      table.insert(replacement, node_text(child) .. " ")
      capture_body = false
    end

    if capture_body then
      body = indent_node_text(child)
    end

    if not capture_body then
      condition = node_text(child)
    end
  end

  replacement = { replacement[1] .. condition, "  " .. body, indent_text("end", start_col) }

  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, replacement)
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

M.node_actions = {
  lua = {
    ["table_constructor"] = toggle_multiline,
    ["arguments"] = toggle_multiline,
    ["true"] = toggle_boolean,
    ["false"] = toggle_boolean,
    ["identifier"] = cycle_case,
  },

  json = {
    ["object"] = toggle_multiline,
    ["array"] = toggle_multiline,
  },

  ruby = {
    ["true"] = toggle_boolean,
    ["false"] = toggle_boolean,
    ["array"] = toggle_multiline,
    ["hash"] = toggle_multiline,
    ["argument_list"] = toggle_multiline,
    ["method_parameters"] = toggle_multiline,
    ["identifier"] = cycle_case,
    ["constant"] = cycle_case,
    ["block"] = toggle_block,
    ["do_block"] = toggle_block,
    ["binary"] = toggle_comparison,
    ["if"] = handle_conditional,
    ["unless"] = handle_conditional,
    ["if_modifier"] = multiline_conditional,
    ["unless_modifier"] = multiline_conditional,
    ["conditional"] = expand_ternary,
  },
}

function M.setup(opts)
  M.node_actions = vim.tbl_deep_extend("force", M.node_actions, opts or {})
end

function M.node_action()
  local node = ts_utils.get_node_at_cursor()
  if not node then
    print("(TS:Action) No node found at cursor")
    return
  end

  if not M.node_actions[vim.o.filetype] then
    print("(TS:Action) No actions defined for filetype: '" .. vim.o.filetype .. "'")
    return
  end

  local action = M.node_actions[vim.o.filetype][node:type()]
  if action then
    action(node)
  else
    print("(TS:Action) No action defined for " .. vim.o.filetype .. " node type: '" .. node:type() .. "'")
  end
  -- print("(TS:Action:Debug) filteype: " .. vim.o.filetype .. ", node type: '" .. node:type() .. "', named: " .. tostring(node:named()) .. ", named children: " .. node:named_child_count())
end

return M
