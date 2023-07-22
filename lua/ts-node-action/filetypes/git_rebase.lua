local helpers = require("ts-node-action.helpers")

local function cycle_command(node)
  local text = helpers.node_text(node)
  if text == "pick" or text == "p" then
    return "fixup"
  elseif text == "fixup" or text == "f" then
    return "reword"
  elseif text == "reword" or text == "r" then
    return "edit"
  elseif text == "edit" or text == "e" then
    return "squash"
  elseif text == "squash" or text == "s" then
    return "exec"
  elseif text == "exec" or text == "x" then
    return "break"
  elseif text == "break" or text == "b" then
    return "drop"
  elseif text == "drop" or text == "d" then
    return "label"
  elseif text == "label" or text == "l" then
    return "reset"
  elseif text == "reset" or text == "t" then
    return "merge"
  elseif text == "merge" or text == "m" then
    return "pick"
  end
end

return {
  ["command"] = cycle_command,
}
