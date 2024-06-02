

 local function ipairs_reverse(seq)



 local max_idx = #seq local i = 0

 local idx = max_idx
 local function _1_()
 local val = seq[idx]
 i = (i + 1)
 idx = (idx - 1)
 if (0 < idx) then
 return i, val else return nil end end return _1_ end

 local function char_by_char(str)
 local max_idx = #str local i = 0

 local function _3_() if (i < max_idx) then
 i = (i + 1) local char = str:sub(i, i)

 return i, char else return nil end end return _3_ end

 local function uncouple_substrings(str, delimiter)






 local result = nil
 local rest = str local reversed_str = str:reverse()

 local function _5_()
 if not ("" == rest) then
 result = rest
 do local _6_ = reversed_str:find(delimiter, 1, true) if (nil ~= _6_) then local idx = _6_ rest = str:sub(1, (-1 - idx)) else end end


 return result else return nil end end return _5_ end

 local function gsplit(str, sep)





 local idx_from = nil local _3fidx_sep_start = 0 local _3fidx_sep_end = 0


 local function _9_()

 if _3fidx_sep_end then
 idx_from = (_3fidx_sep_end + 1) _3fidx_sep_start, _3fidx_sep_end = str:find(sep, (idx_from + 1), true)

 local _3fidx_to if _3fidx_sep_start then
 _3fidx_to = (_3fidx_sep_start - 1) else _3fidx_to = nil end return str:sub(idx_from, _3fidx_to) else return nil end end return _9_ end


 local function pairs_from_longer_key(tbl)



 local keys do local tbl_21_auto = {} local i_22_auto = 0 for k, _ in pairs(tbl) do
 local val_23_auto = k if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) do end (tbl_21_auto)[i_22_auto] = val_23_auto else end end keys = tbl_21_auto end
 local function _13_(a, b)
 return (#b < #a) end table.sort(keys, _13_) local i = 0

 local function _14_()
 i = (i + 1)
 local key = keys[i]
 return key, tbl[key] end return _14_ end

 local function each_file(call, dir_path)

 for path, fs_type in vim.fs.dir(dir_path, {depth = math.huge}) do
 if (fs_type == "file") then
 call(path) elseif (fs_type == "directory") then
 each_file(call, path) elseif (nil ~= fs_type) then local _else = fs_type
 error(("expected :file or :directory, got " .. _else)) else end end return nil end

 local function double_quoted_or_else(text) local pat_double_quoted = "^\".-[^\\]\"" local pat_empty_string = "^\"\"" local pat_else = "^[^\"]+"







 local patterns = {pat_double_quoted, pat_empty_string, pat_else}
 local max_idx = #patterns
 local rest = text
 local function _16_()
 local result = nil for i, pat in ipairs(patterns) do if result then break end local _17_, _18_ = rest:find(pat)

 if ((nil ~= _17_) and (nil ~= _18_)) then local idx_from = _17_ local idx_to = _18_ local result0 = rest:sub(idx_from, idx_to) rest = rest:sub((1 + idx_to))


 result = result0 else local _ = _17_
 if ((i == max_idx) and ("" ~= rest)) then
 result = error(("expected empty string, failed to consume the rest of the string.\n- Consumed text:\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n%s\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n- The rest:\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n%s\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"):format(text:sub(1, (1 - #rest)), rest)) else result = nil end end end return result end return _16_ end











 local function string_or_else(text) local pat_string = "^\".-[^\\]\"" local pat_empty_string = "^\"\"" local pat_spaces = "^[%s\n]+" local pat_colon_string = "^:[^%])}%s\n]+" local pat_non_string = "^[^\"]+"









 local patterns = {pat_spaces, pat_string, pat_empty_string, pat_colon_string, pat_non_string}




 local max_idx = #patterns
 local rest = text
 local last_pat = nil
 local last_matched = nil
 local function _21_()


 local result = nil for i, pat in ipairs(patterns) do if result then break end local _22_, _23_ = rest:find(pat)

 if ((nil ~= _22_) and (nil ~= _23_)) then local idx_from = _22_ local idx_to = _23_ local result0 = rest:sub(idx_from, idx_to)

 last_pat = pat
 last_matched = result0 rest = rest:sub((1 + idx_to))

 result = result0 else local _ = _22_
 if ((i == max_idx) and ("" ~= rest)) then
 result = error(("expected empty string, failed to consume the rest of the string.\n- Consumed text:\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n%s\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\nThe last matched pattern: %s\n\nThe last matched string:\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n%s\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n\n- The rest:\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n%s\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"):format(text:sub(1, (1 - #rest)), last_pat, last_matched, rest)) else result = nil end end end return result end return _21_ end




















 local function walk_tree(root, f, _3fcustom_iterator)


 local function walk(iterfn, parent, idx, node)
 if f(idx, node, parent) then
 for k, v in iterfn(node) do
 walk(iterfn, node, k, v) end return nil else return nil end end

 walk((_3fcustom_iterator or pairs), nil, nil, root)
 return root end

 return {["ipairs-reverse"] = ipairs_reverse, ["char-by-char"] = char_by_char, ["uncouple-substrings"] = uncouple_substrings, gsplit = gsplit, ["pairs-from-longer-key"] = pairs_from_longer_key, ["each-file"] = each_file, ["double-quoted-or-else"] = double_quoted_or_else, ["string-or-else"] = string_or_else, ["walk-tree"] = walk_tree}
