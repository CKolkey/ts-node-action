local helpers = require("ts-node-action.helpers")

local function group_string(string, group_size)
  local groups = {}

  while #string > group_size do
    table.insert(groups, string:sub(1, group_size))
    string = string:sub(group_size + 1)
  end

  table.insert(groups, string)

  return groups
end

return function(delimiter)
  delimiter = delimiter or "_"

  local function action(node)
    local text = helpers.node_text(node)
    if #text > 3 then
      if string.find(text, delimiter) then
        text = text:gsub(delimiter, "")
      else
        text = table.concat(group_string(text:reverse(), 3), delimiter):reverse()
      end
    end

    return text
  end

  return { { action, name = "Toggle Integer Format" } }
end
