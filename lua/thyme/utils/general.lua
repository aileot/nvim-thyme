local function do_nothing()
  return nil
end
local function contains_3f(xs, _3fa)
  local eq_3f = false
  for i = 1, #xs do
    if eq_3f then break end
    eq_3f = (_3fa == xs[i])
  end
  return eq_3f
end
local function validate_type(expected, val)
  local t = type(val)
  if not (t == expected) then
    return error(("expected " .. expected .. t))
  else
    return nil
  end
end
local function new_matrix(row, col, val)
  local matrix = {}
  if col then
    assert(row, "missing row value")
    for i = 1, row do
      rawset(matrix, i, {})
      for j = 1, col do
        matrix[i][j] = val
      end
    end
  else
  end
  local function _3_(self, key)
    local tbl = {}
    rawset(self, key, tbl)
    return tbl
  end
  return setmetatable(matrix, {__index = _3_})
end
local function warn_21(raw_msg)
  local msg = ("[thyme] " .. raw_msg)
  return vim.notify(msg, vim.log.levels.WARN)
end
local function sorter_2ffiles_to_oldest_by_birthtime(file1, file2)
  local _let_4_ = vim.uv.fs_stat(file1).birthtime
  local sec1 = _let_4_["sec"]
  local nsec1 = _let_4_["nsec"]
  local _let_5_ = vim.uv.fs_stat(file2).birthtime
  local sec2 = _let_5_["sec"]
  local nsec2 = _let_5_["nsec"]
  return ((sec2 < sec1) or ((sec2 == sec1) and (nsec2 < nsec1)))
end
return {["do-nothing"] = do_nothing, ["contains?"] = contains_3f, ["validate-type"] = validate_type, ["new-matrix"] = new_matrix, ["warn!"] = warn_21, ["sorter/files-to-oldest-by-birthtime"] = sorter_2ffiles_to_oldest_by_birthtime}
