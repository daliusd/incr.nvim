local M = {}

_G.selected_nodes = {} ---@type TSNode[]

local function get_node_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local ok, root_parser = pcall(vim.treesitter.get_parser, 0, nil, {})
  if not ok or not root_parser then
    return
  end

  root_parser:parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
  local lang_tree = root_parser:language_for_range({ row, col, row, col })

  return lang_tree:named_node_for_range({ row, col, row, col }, { ignore_injections = false })
end

local function select_node(node)
  if not node then
    return
  end
  local start_row, start_col, end_row, end_col = node:range()

  local last_line = vim.api.nvim_buf_line_count(0)
  local end_row_pos = math.min(end_row + 1, last_line)
  local end_col_pos = end_col

  if end_row + 1 > last_line then
    local last_line_text = vim.api.nvim_buf_get_lines(0, last_line - 1, last_line, true)[1]
    end_col_pos = #last_line_text
  end

  -- enter visual mode if normal or operator-pending (no) mode
  -- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
  --   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
  --   Otherwise, Vim will operate on the text between the original cursor position and the new position.
  local mode = vim.api.nvim_get_mode()
  if mode.mode ~= 'v' then
    vim.api.nvim_cmd({ cmd = 'normal', bang = true, args = { 'v' } }, {})
  end

  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd('normal! o')
  vim.api.nvim_win_set_cursor(0, { end_row_pos, end_col_pos > 0 and end_col_pos - 1 or 0 })
end

local function in_cmd_buf(key)
    if vim.fn.getcmdwintype() == '' then return false end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return true
end

M.setup = function(config)
  local incr_key = config.incr_key and config.incr_key or '<tab>'
  local decr_key = config.decr_key and config.decr_key or '<s-tab>'

  vim.keymap.set({ 'n' }, incr_key, function()
    if in_cmd_buf(incr_key) then return end
    _G.selected_nodes = {}

    local current_node = get_node_at_cursor()
    if not current_node then
      return
    end

    table.insert(_G.selected_nodes, current_node)
    select_node(current_node)
  end, { desc = 'Select treesitter node' })

  vim.keymap.set('x', incr_key, function()
    if #_G.selected_nodes == 0 then
      return
    end

    local current_node = _G.selected_nodes[#_G.selected_nodes]

    if not current_node then
      return
    end

    local node = current_node
    local root_searched = false
    while true do
      local parent = node:parent()
      if not parent then
        if root_searched then
          return
        end
        local ok, root_parser = pcall(vim.treesitter.get_parser)
        if not ok or root_parser == nil then
          return
        end
        root_parser:parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })

        local range = { node:range() }
        local current_parser = root_parser:language_for_range(range)

        if root_parser ~= current_parser then
          local parser = current_parser:parent()
          if parser == nil then
            return
          end
          current_parser = parser
        end

        if root_parser == current_parser then
          root_searched = true
        end

        parent = current_parser:named_node_for_range(range)
        if parent == nil then
          return
        end
      end

      local range = { node:range() }
      local parent_range = { parent:range() }
      if not vim.deep_equal(range, parent_range) then
        table.insert(_G.selected_nodes, parent)
        select_node(parent)
        return
      end
      node = parent
    end
  end, { desc = 'Increment selection' })

  vim.keymap.set('x', decr_key, function()
    if in_cmd_buf(decr_key) then return end
    if #_G.selected_nodes > 1 then
      table.remove(_G.selected_nodes)
      local current_node = _G.selected_nodes[#_G.selected_nodes]
      if current_node then
        select_node(current_node)
      end
    end
  end, { desc = 'Decrement selection' })
end

return M
