local function buf_get_text_in_range(buf, start, _end)
  local _3_
  do
    local case_1_, case_2_ = start, _end
    if (((_G.type(case_1_) == "table") and (nil ~= case_1_[1]) and (nil ~= case_1_[2])) and ((_G.type(case_2_) == "table") and (nil ~= case_2_[1]) and (nil ~= case_2_[2]))) then
      local row1 = case_1_[1]
      local col01 = case_1_[2]
      local row2 = case_2_[1]
      local col02 = case_2_[2]
      _3_ = vim.api.nvim_buf_get_text(buf, (row1 - 1), col01, (row2 - 1), (col02 + 1), {})
    elseif ((nil ~= case_1_) and (nil ~= case_2_)) then
      local row1 = case_1_
      local row2 = case_2_
      _3_ = vim.api.nvim_buf_get_lines(buf, (row1 - 1), row2, true)
    else
      _3_ = nil
    end
  end
  return table.concat(_3_, "\n")
end
local function buf_marks__3etext(...)
  local buf, mark1, mark2
  do
    local case_7_ = select("#", ...)
    if (case_7_ == 2) then
      buf, mark1, mark2 = 0, ...
    elseif (case_7_ == 3) then
      buf, mark1, mark2 = ...
    else
      local _ = case_7_
      buf, mark1, mark2 = error(("expected 2 or 3 args, got " .. table.concat({...}, ",")))
    end
  end
  local start, _end
  do
    local case_9_, case_10_ = vim.api.nvim_buf_get_mark(buf, mark1), vim.api.nvim_buf_get_mark(buf, mark2)
    if (((_G.type(case_9_) == "table") and (nil ~= case_9_[1])) and ((_G.type(case_10_) == "table") and (nil ~= case_10_[1]))) then
      local row1 = case_9_[1]
      local start0 = case_9_
      local row2 = case_10_[1]
      local _end0 = case_10_
      if (row1 <= row2) then
        start, _end = start0, _end0
      else
        start, _end = _end0, start0
      end
    else
      start, _end = nil
    end
  end
  local end_row = _end[1]
  local _let_13_ = vim.api.nvim_buf_get_lines(buf, (end_row - 1), end_row, true)
  local end_line = _let_13_[1]
  local end_col = #end_line
  local linewise_3f = (end_col < _end[2])
  local text
  if linewise_3f then
    text = buf_get_text_in_range(0, start[1], _end[1])
  else
    text = buf_get_text_in_range(0, start, _end)
  end
  return text
end
return {["buf-get-text-in-range"] = buf_get_text_in_range, ["buf-marks->text"] = buf_marks__3etext}
