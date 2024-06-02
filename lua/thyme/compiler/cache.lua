


 local Path = require("thyme.utils.path")

 local _local_1_ = require("thyme.const") local lua_cache_prefix = _local_1_["lua-cache-prefix"]
 local _local_2_ = require("thyme.utils.pool") local hide_dir_21 = _local_2_["hide-dir!"]
 local _local_3_ = require("thyme.module-map.logger") local clear_dependency_log_files_21 = _local_3_["clear-dependency-log-files!"]

 local function module_name__3elua_path(module_name)






 local lua_module_path = (module_name:gsub("%.", Path.sep) .. ".lua")
 return Path.join(lua_cache_prefix, lua_module_path) end

 local function delete_cache_files_21()

 hide_dir_21(lua_cache_prefix)
 return clear_dependency_log_files_21() end

 local function clear_cache_21(_3fopts)



 local opts = (_3fopts or {})
 local path = lua_cache_prefix local idx_yes = 2 local _3fidx

 if (false == opts.prompt) then
 _3fidx = idx_yes else _3fidx = nil end
 local _5_ = (_3fidx or vim.fn.confirm(("Remove cache files under %s?"):format(path), "&No\n&yes", 1, "Warning")) if (_5_ == idx_yes) then



 delete_cache_files_21()
 return vim.notify(("Cleared cache: " .. path)) else local _ = _5_
 return vim.notify(("Abort. " .. path .. " is already cleared.")) end end

 return {["module-name->lua-path"] = module_name__3elua_path, ["clear-cache!"] = clear_cache_21}
