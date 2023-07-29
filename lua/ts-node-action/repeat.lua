-- https://github.com/lewis6991/gitsigns.nvim/blob/main/lua/gitsigns/repeat.lua
local M = {}

function M.set(fn)
  return function(...)
    local args = { ... }
    local nargs = select("#", ...)
    vim.go.operatorfunc = "v:lua.require'ts-node-action.repeat'.repeat_action"

    M.repeat_action = function()
      fn(unpack(args, 1, nargs))

      local action = vim.api.nvim_replace_termcodes(
        string.format("<cmd>call %s()<cr>", vim.go.operatorfunc),
        true,
        true,
        true
      )

      pcall(vim.fn["repeat#set"], action, -1)
    end

    vim.cmd("normal! g@l")
  end
end

return M
