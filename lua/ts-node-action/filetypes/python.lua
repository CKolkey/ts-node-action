local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
}

local toggle_multiline = require("ts-node-action.actions.toggle_multiline")(padding)

local function toggle_boolean(node)
  local value, _ = tostring(node:type() ~= "true"):gsub("^%l", string.upper)
  return value
end

return {
  ["dictionary"]    = toggle_multiline,
  ["list"]          = toggle_multiline,
  ["argument_list"] = toggle_multiline,
  ["parameters"]    = toggle_multiline,
  ["true"]          = toggle_boolean,
  ["false"]         = toggle_boolean,
}
