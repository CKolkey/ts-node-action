local namespace = vim.api.nvim_create_namespace("ts_node_action_conceal")

return function(char, level, cursor)
  char = char or ""
  level = level or 2
  cursor = cursor or "nc"

  local function action(node)
    vim.api.nvim_win_set_option(0, "concealcursor", cursor)
    vim.api.nvim_win_set_option(0, "conceallevel", level)

    local start_row, start_col, end_row, end_col = node:range()
    local extmark_id = unpack(
      vim.api.nvim_buf_get_extmarks(
        0,
        namespace,
        { start_row, start_col },
        { end_row, end_col },
        {}
      )[1] or {}
    )

    if extmark_id then
      vim.api.nvim_buf_del_extmark(0, namespace, extmark_id)
    else
      vim.api.nvim_buf_set_extmark(
        0,
        namespace,
        start_row,
        start_col,
        { end_row = end_row, end_col = end_col, conceal = char }
      )
    end
  end

  return { { action, name = "Conceal String" } }
end
