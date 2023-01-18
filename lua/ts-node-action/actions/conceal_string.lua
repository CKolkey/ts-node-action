local namespace = vim.api.nvim_create_namespace('ts_node_action_conceal')

return function(conceal_char, conceal_level)
  conceal_char = conceal_char or ""
  vim.wo[vim.api.nvim_get_current_win()].conceallevel = conceal_level or 1

  return function(node)
    local start_row, start_col, end_row, end_col = node:range()
    local extmark_id = vim.api.nvim_buf_get_extmarks(0, namespace, { start_row, start_col }, { end_row, end_col }, {})

    if extmark_id[1] then
      vim.api.nvim_buf_del_extmark(0, namespace, extmark_id[1][1])
    else
      vim.api.nvim_buf_set_extmark(
        0, namespace, start_row, start_col, { end_row = end_row, end_col = end_col, conceal = conceal_char }
      )
    end
  end
end
