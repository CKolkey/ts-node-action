local helpers = require("ts-node-action.helpers")

local snake_case = {
  check = function(text)
    return (string.find(text, "_")
      and string.sub(text, 1, 1) == string.sub(text, 1, 1):lower())
      or text:lower() == text
  end,

  transform = function(tbl)
    return string.lower(table.concat(tbl, "_"))
  end,

  standardize = function(text)
    return vim.split(string.lower(text), "_", { trimempty = true })
  end
}

local camel_case = {
  transform = function(tbl)
    local tmp = vim.tbl_map(function(word)
      return word:gsub("^.", string.upper)
    end, tbl)
    local value, _ = table.concat(tmp, ""):gsub("^.", string.lower)
    return value
  end,

  standardize = function(text)
    local tmp = text:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper)
    return vim.split(tmp, " ", { trimempty = true })
  end
}

local pascal_case = {
  check = function(text)
    return string.sub(text, 1, 1) == string.sub(text, 1, 1):upper()
  end,

  transform = function(tbl)
    local tmp = vim.tbl_map(function(word)
      return word:gsub("^.", string.upper)
    end, tbl)

    local value, _ = table.concat(tmp, "")

    return value
  end,

  standardize = function(text)
    local tmp = text:gsub(".%f[%l]", " %1"):gsub("%l%f[%u]", "%1 "):gsub("^.", string.upper)
    return vim.split(tmp, " ", { trimempty = true })
  end
}

local screaming_snake_case = {
  check = function(text)
    return string.sub(text, 1, 2) == string.sub(text, 1, 2):upper()
  end,

  transform = function(tbl)
    local tmp = vim.tbl_map(function(word)
      return word:upper()
    end, tbl)

    local value, _ = table.concat(tmp, "_")

    return value
  end,

  standardize = function(text)
    return vim.split(string.lower(text), "_", { trimempty = true })
  end
}

return function(node)
  local text = helpers.node_text(node)
  local standardize
  local transform

  if snake_case.check(text) then
    standardize = snake_case.standardize
    transform   = pascal_case.transform
  elseif screaming_snake_case.check(text) then
    standardize = screaming_snake_case.standardize
    transform   = camel_case.transform
  elseif pascal_case.check(text) then
    standardize = pascal_case.standardize
    transform   = screaming_snake_case.transform
  else
    standardize = camel_case.standardize
    transform   = snake_case.transform
  end

  return transform(standardize(text))
end
