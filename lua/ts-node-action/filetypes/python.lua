local actions = require("ts-node-action.actions")

local padding = {
  [","] = "%s ",
  [":"] = "%s ",
  ["{"] = "%s ",
  ["}"] = " %s",
}

local boolean_override = {
  ["True"]  = "False",
  ["False"] = "True",
}

return {
  ["dictionary"]          = actions.toggle_multiline(padding),
  ["list"]                = actions.toggle_multiline(padding),
  ["argument_list"]       = actions.toggle_multiline(padding),
  ["parameters"]          = actions.toggle_multiline(padding),
  ["true"]                = actions.toggle_boolean(boolean_override),
  ["false"]               = actions.toggle_boolean(boolean_override),
  ["comparison_operator"] = actions.toggle_operator(),
}
