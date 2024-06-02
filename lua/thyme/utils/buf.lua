

 local function buf_get_text_in_range(buf, start, _end)








 local _3_ do local _1_, _2_ = start, _end if (((_G.type(_1_) == "table") and (nil ~= _1_[1]) and (nil ~= _1_[2])) and ((_G.type(_2_) == "table") and (nil ~= _2_[1]) and (nil ~= _2_[2]))) then local row1 = _1_[1] local col01 = _1_[2] local row2 = _2_[1] local col02 = _2_[2]

 _3_ = vim.api.nvim_buf_get_text(buf, (row1 - 1), col01, (row2 - 1), (col02 + 1), {}) elseif ((nil ~= _1_) and (nil ~= _2_)) then local row1 = _1_ local row2 = _2_

 _3_ = vim.api.nvim_buf_get_lines(buf, (row1 - 1), row2, true) else _3_ = nil end end return table.concat(_3_, "\n") end


 local function buf_marks__3etext(...)





 local buf, mark1, mark2 = nil, nil, nil do local _7_ = select("#", ...) if (_7_ == 2) then
 buf, mark1, mark2 = 0, ... elseif (_7_ == 3) then
 buf, mark1, mark2 = ... else local _ = _7_
 buf, mark1, mark2 = error(("expected 2 or 3 args, got " .. table.concat({...}, ","))) end end local start, _end = nil, nil

 do local _9_, _10_ = vim.api.nvim_buf_get_mark(buf, mark1), vim.api.nvim_buf_get_mark(buf, mark2) if (((_G.type(_9_) == "table") and (nil ~= _9_[1])) and ((_G.type(_10_) == "table") and (nil ~= _10_[1]))) then local row1 = _9_[1] local start0 = _9_ local row2 = _10_[1] local _end0 = _10_

 if (row1 <= row2) then
 start, _end = start0, _end0 else
 start, _end = _end0, start0 end else start, _end = nil end end
 local end_row = _end[1]




 local _let_13_ = vim.api.nvim_buf_get_lines(buf, (end_row - 1), end_row, true) local end_line = _let_13_[1]
 local end_col = #end_line
 local linewise_3f = (end_col < _end[2]) local text
 if linewise_3f then
 text = buf_get_text_in_range(0, start[1], _end[1]) else
 text = buf_get_text_in_range(0, start, _end) end
 return text end

 return {["buf-get-text-in-range"] = buf_get_text_in_range, ["buf-marks->text"] = buf_marks__3etext}
