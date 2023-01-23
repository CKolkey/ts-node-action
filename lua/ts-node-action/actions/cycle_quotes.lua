local helpers = require("ts-node-action.helpers")

return function(quotes)
  quotes = quotes or { { "'", "'" }, { '"', '"' } }

  local function action(node)
    local text = helpers.node_text(node)
    for i, char in ipairs(quotes) do
      if string.sub(text, 1, #char[1]) == char[1] then
        local next      = quotes[i + 1 > #quotes and 1 or i + 1]
        local substring = string.sub(text, #char[1] + 1, -(#char[2] + 1))

        return next[1] .. substring .. next[2], { cursor = {} }
      end
    end
  end

  return { { action, name = "Cycle Quotes" } }
end
