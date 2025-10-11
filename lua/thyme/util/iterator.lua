local Path = require("thyme.util.path")
local function ipairs_reverse(seq)
  local max_idx = #seq
  local i = 0
  local idx = max_idx
  local function _1_()
    local val = seq[idx]
    i = (i + 1)
    idx = (idx - 1)
    if (0 < idx) then
      return i, val
    else
      return nil
    end
  end
  return _1_
end
local function char_by_char(str)
  local max_idx = #str
  local i = 0
  local function _3_()
    if (i < max_idx) then
      i = (i + 1)
      local char = str:sub(i, i)
      return i, char
    else
      return nil
    end
  end
  return _3_
end
local function uncouple_substrings(str, delimiter)
  local result = nil
  local rest = str
  local reversed_str = str:reverse()
  local function _5_()
    if not ("" == rest) then
      result = rest
      do
        local case_6_ = reversed_str:find(delimiter, 1, true)
        if (nil ~= case_6_) then
          local idx = case_6_
          rest = str:sub(1, (-1 - idx))
        else
        end
      end
      return result
    else
      return nil
    end
  end
  return _5_
end
local function gsplit(str, sep)
  local idx_from = nil
  local _3fidx_sep_start = 0
  local _3fidx_sep_end = 0
  local function _9_()
    if _3fidx_sep_end then
      idx_from = (_3fidx_sep_end + 1)
      _3fidx_sep_start, _3fidx_sep_end = str:find(sep, (idx_from + 1), true)
      local _3fidx_to
      if _3fidx_sep_start then
        _3fidx_to = (_3fidx_sep_start - 1)
      else
        _3fidx_to = nil
      end
      return str:sub(idx_from, _3fidx_to)
    else
      return nil
    end
  end
  return _9_
end
local function pairs_from_longer_key(tbl)
  local keys
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for k, _ in pairs(tbl) do
      local val_28_ = k
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    keys = tbl_26_
  end
  local function _13_(a, b)
    return (#b < #a)
  end
  table.sort(keys, _13_)
  local i = 0
  local function _14_()
    i = (i + 1)
    local key = keys[i]
    return key, tbl[key]
  end
  return _14_
end
local function each_file(call, dir_path)
  for relative_path, fs_type in vim.fs.dir(dir_path, {depth = 1}) do
    local full_path = Path.join(dir_path, relative_path)
    if (fs_type == "file") then
      call(full_path)
    elseif (fs_type == "directory") then
      each_file(call, full_path)
    elseif (fs_type == "link") then
      call(full_path)
    elseif (nil ~= fs_type) then
      local _else = fs_type
      error(("expected :file or :directory, got " .. _else))
    else
    end
  end
  return nil
end
local function each_dir(call, dir_path)
  for relative_path, fs_type in vim.fs.dir(dir_path, {depth = 1}) do
    local full_path = Path.join(dir_path, relative_path)
    if (fs_type == "directory") then
      each_dir(call, full_path)
      call(full_path)
    else
    end
  end
  return nil
end
local function walk_tree(root, f, _3fcustom_iterator)
  local function walk(iterfn, parent, idx, node)
    if f(idx, node, parent) then
      for k, v in iterfn(node) do
        walk(iterfn, node, k, v)
      end
      return nil
    else
      return nil
    end
  end
  walk((_3fcustom_iterator or pairs), nil, nil, root)
  return root
end
return {["ipairs-reverse"] = ipairs_reverse, ["char-by-char"] = char_by_char, ["uncouple-substrings"] = uncouple_substrings, gsplit = gsplit, ["pairs-from-longer-key"] = pairs_from_longer_key, ["each-file"] = each_file, ["each-dir"] = each_dir, ["walk-tree"] = walk_tree}
