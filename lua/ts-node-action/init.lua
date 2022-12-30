local M = {}

M.node_actions = {
  lua = require("ts-node-action/filetypes/lua"),
  json = require("ts-node-action/filetypes/json"),
  ruby = require("ts-node-action/filetypes/ruby"),
}

function M.setup(opts)
  M.node_actions = vim.tbl_deep_extend("force", M.node_actions, opts or {})
end

function M.node_action()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if not node then
    print("(ts-node-action) No node found at cursor")
    return
  end

  if not M.node_actions[vim.o.filetype] then
    print("(ts-node-action) No actions defined for filetype: '" .. vim.o.filetype .. "'")
    return
  end

  local action = M.node_actions[vim.o.filetype][node:type()]
  if action then
    action(node)
  else
    print("(ts-node-action) No action defined for " .. vim.o.filetype .. " node type: '" .. node:type() .. "'")
  end
end

function M.debug()
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  print(vim.inspect(
    {
      node = {
        filetype = vim.o.filetype,
        node_type = node:type(),
        named = node:named(),
        named_children = node:named_child_count(),
      },
      plugin = {
        node_actions = M.node_actions
      }
    }
  ))
end

return M
