



 local _local_1_ = require("thyme.user.check") local check_to_update_21 = _local_1_["check-to-update!"]

 local _3fgroup = nil







 local watch_autocmds = {}
 local function watch_to_update_21(_3fopts)









 local group local function _2_(...) return vim.api.nvim_create_augroup("ThymeWatch", {}) end group = (_3fgroup or _2_())
 local opts = (_3fopts or {})

 local event = (opts.event or {"BufWritePost", "FileChangedShellPost"})
 local pattern = (opts.pattern or "*.fnl") local callback
 local function _4_(_3_) local fnl_path = _3_["match"]
 return check_to_update_21(fnl_path, opts) end callback = _4_
 _3fgroup = group local id = vim.api.nvim_create_autocmd(event, {group = group, pattern = pattern, callback = callback})

 if watch_autocmds[event] then
 local _3fid_duplicated_pattern = watch_autocmds[event][pattern]
 if _3fid_duplicated_pattern then
 vim.api.nvim_del_autocmd(_3fid_duplicated_pattern) else end else
 watch_autocmds[event] = {} end
 watch_autocmds[event][pattern] = id return nil end

 return {["watch-to-update!"] = watch_to_update_21}
