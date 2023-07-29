local helpers = require("ts-node-action.helpers")

-- API Notes:
-- Every format is a table that implements the following three keys:
-- - pattern
-- - apply
-- - standardize
--
-- # Pattern
-- A Lua pattern (string) that matches the format
--
-- # Apply
-- A function that takes a _table_ of standardized strings as it's argument, and returns a _string_ in the format
--
-- # Standardize
-- A function that takes a _string_ in this format, and returns a table of strings, all lower case, no special chars.
-- ie: standardize("ts_node_action") -> { "ts", "node", "action" }
--     standardize("tsNodeAction")   -> { "ts", "node", "action" }
--     standardize("TsNodeAction")   -> { "ts", "node", "action" }
--     standardize("TS_NODE_ACTION") -> { "ts", "node", "action" }
--
-- NOTE: The order of formats can be important, as some identifiers are the same for multiple formats.
--   Take the string 'action' for example. This is a match for both snake_case _and_ camel_case. It's
--   therefore important to place a format between those two so we can correcly change the string.

local format_table = {
  snake_case = {
    pattern = "^%l+[%l_]*$",
    apply = function(tbl)
      return string.lower(table.concat(tbl, "_"))
    end,
    standardize = function(text)
      return vim.split(string.lower(text), "_", { trimempty = true })
    end,
  },
  camel_case = {
    pattern = "^%l+[%u%l]*$",
    apply = function(tbl)
      local tmp = vim.tbl_map(function(word)
        return word:gsub("^.", string.upper)
      end, tbl)
      local value, _ = table.concat(tmp, ""):gsub("^.", string.lower)
      return value
    end,
    standardize = function(text)
      return vim.split(
        text
          :gsub(".%f[%l]", " %1")
          :gsub("%l%f[%u]", "%1 ")
          :gsub("^.", string.upper),
        " ",
        { trimempty = true }
      )
    end,
  },
  pascal_case = {
    pattern = "^%u%l+[%u%l]*$",
    apply = function(tbl)
      local value, _ = table.concat(
        vim.tbl_map(function(word)
          return word:gsub("^.", string.upper)
        end, tbl),
        ""
      )
      return value
    end,
    standardize = function(text)
      return vim.split(
        text
          :gsub(".%f[%l]", " %1")
          :gsub("%l%f[%u]", "%1 ")
          :gsub("^.", string.upper),
        " ",
        { trimempty = true }
      )
    end,
  },
  screaming_snake_case = {
    pattern = "^%u+[%u_]*$",
    apply = function(tbl)
      local value, _ = table.concat(
        vim.tbl_map(function(word)
          return word:upper()
        end, tbl),
        "_"
      )

      return value
    end,
    standardize = function(text)
      return vim.split(string.lower(text), "_", { trimempty = true })
    end,
  },
}

local function check_pattern(text, pattern)
  return not not string.find(text, pattern)
end

local default_formats =
  { "snake_case", "pascal_case", "screaming_snake_case", "camel_case" }

return function(user_formats)
  user_formats = user_formats or default_formats

  local formats = {}
  for _, format in ipairs(user_formats) do
    if type(format) == "string" then
      format = format_table[format]
    end

    if format then
      table.insert(formats, format)
    else
      print("TS:NodeAction:CycleCase - Format '" .. format .. "' is invalid")
    end
  end

  local function action(node)
    local text = helpers.node_text(node)

    for i, format in ipairs(formats) do
      if check_pattern(text, format.pattern) then
        local next_i = i + 1 > #formats and 1 or i + 1
        local apply = formats[next_i].apply
        local standardize = format.standardize

        return apply(standardize(text))
      end
    end
  end

  return { { action, name = "Cycle Case" } }
end
