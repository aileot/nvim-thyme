 local function get_runtime_files(pats, all_3f)






 local files = {}
 if all_3f then
 for _, pat in ipairs(pats) do
 for _0, f in ipairs(vim.api.nvim_get_runtime_file(pat, all_3f)) do
 table.insert(files, f) end end else
 for _, pat in ipairs(pats) do if files[1] then break end
 local _1_ = vim.api.nvim_get_runtime_file(pat, all_3f) if ((_G.type(_1_) == "table") and (nil ~= _1_[1])) then local path = _1_[1]
 files[1] = path else end end end
 return files end

 return {["get-runtime-files"] = get_runtime_files}
