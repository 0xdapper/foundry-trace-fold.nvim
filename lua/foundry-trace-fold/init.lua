local M = {}

local ext_call_regex = "%s+%[%d+%] .+"
local top_level_ext_call_regex = "^" .. ext_call_regex
local trace_line_regex = "^%s+[│├└]"
local box_drawing_vertical = "│"
local box_drawing_vertical_and_right = "├"
local box_drawing_up_and_right = "└"

function get_depth(line)
  local line = line or ""
  -- not a trace line, depth is 0
  if not line:match(trace_line_regex) then
    return 0
  end

  -- local _, depth = line:gsub("(%s+[│├└])", "")
  local _, n_dv = line:gsub(box_drawing_vertical, "")
  local _, n_dvr = line:gsub(box_drawing_vertical_and_right, "")
  local _, n_dur = line:gsub(box_drawing_up_and_right, "")
  local depth = n_dv + n_dvr + n_dur
  return depth and (depth + 1) or 0
end

function M.calculate_fold_level(current_line, next_line)
  -- if top level ext call, return 1
  if current_line:match(top_level_ext_call_regex) then
    return ">1"
  end

  -- if not a trace line, return 0
  if not current_line:match(trace_line_regex) then
    return "0"
  end

  local depth = get_depth(current_line)
  local next_depth = get_depth(next_line)
  -- print(depth, next_depth)
  if next_depth < depth then
    return "<" .. depth
  else
    return ">" .. depth
  end
end

function M.get_fold(lnum)
  local line = vim.fn.getline(lnum)
  local next_line = vim.fn.getline(lnum + 1)
  local bufnr = vim.api.nvim_get_current_buf()
  local fold_level = M.calculate_fold_level(line, next_line)

  -- Update debug info if debug mode is on
  if M.debug then
    vim.schedule(function()
      local is_closed = vim.fn.foldclosed(lnum) ~= -1
      M.update_debug_info(bufnr, lnum, fold_level, is_closed)
    end)
  end

  return fold_level
end

-- Add debug state
M.debug = false

-- Function to update debug info
function M.update_debug_info(bufnr, lnum, fold_level, is_closed)
  if not M.debug then
    return
  end

  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(bufnr, -1, lnum - 1, lnum)

  -- Create debug text
  local debug_text = string.format("level: %s, %s", tostring(fold_level), is_closed and "closed" or "open")

  -- Add virtual text
  vim.api.nvim_buf_set_virtual_text(
    bufnr,
    -1,       -- create new namespace
    lnum - 1, -- 0-based line number
    { { debug_text, "Comment" } },
    {}
  )
end

-- Function to toggle debug mode
function M.toggle_debug()
  M.debug = not M.debug
  local bufnr = vim.api.nvim_get_current_buf()

  if not M.debug then
    -- Clear all virtual text when turning debug off
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
    return
  end

  -- Update all lines when turning debug on
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  for lnum = 1, line_count do
    local fold_level = vim.fn.foldlevel(lnum)
    local is_closed = vim.fn.foldclosed(lnum) ~= -1
    M.update_debug_info(bufnr, lnum, fold_level, is_closed)
  end
end

M.foldexpr = 'v:lua.require("foundry-trace-fold").get_fold(v:lnum)'

function M.setup()
  local function create_cmd(name, callback)
    if vim.fn.exists(":" .. name) == 0 then
      vim.api.nvim_create_user_command(name, callback, {})
    end
  end

  -- Add command to toggle debug mode
  create_cmd("FoundryFoldDebugToggle", function()
    M.toggle_debug()
  end)

  -- Add command to toggle foundry fold
  create_cmd("FoundryFoldToggle", function()
    local winid = vim.api.nvim_get_current_win()
    local foldmethod = vim.wo[winid].foldmethod
    local foldexpr = vim.wo[winid].foldexpr

    if M._cache == nil then
      M._cache = {}
    end

    if foldmethod == "expr" and foldexpr == M.foldexpr then
      -- restore previous foldmethod and foldexpr
      local prev_setting = M._cache[winid] or {}
      if prev_setting.foldmethod then
        vim.wo[winid].foldmethod = prev_setting.foldmethod
      end
      if prev_setting.foldexpr then
        vim.wo[winid].foldexpr = prev_setting.foldexpr
      end
      M._cache[winid] = nil
    else
      -- cache current foldmethod and foldexpr for future toggle
      M._cache[winid] = { foldmethod = foldmethod, foldexpr = foldexpr }
      vim.wo[winid].foldmethod = "expr"
      vim.wo[winid].foldexpr = M.foldexpr
    end
  end)
end

return M
