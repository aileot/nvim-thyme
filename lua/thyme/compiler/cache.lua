local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.utils.pool")
local hide_files_in_dir_21 = _local_2_["hide-files-in-dir!"]
local _local_3_ = require("thyme.module-map.logger")
local clear_dependency_log_files_21 = _local_3_["clear-dependency-log-files!"]
local function module_name__3elua_path(module_name)
  local lua_module_path = (module_name:gsub("%.", Path.sep) .. ".lua")
  return Path.join(lua_cache_prefix, lua_module_path)
end
local function clear_cache_21()
  local _4_ = vim.fs.find("fennel.lua", {type = "file", path = lua_cache_prefix})
  if ((_G.type(_4_) == "table") and (_4_[1] == nil)) then
    return false
  else
    local _ = _4_
    hide_files_in_dir_21(lua_cache_prefix)
    clear_dependency_log_files_21()
    return true
  end
end
return {["module-name->lua-path"] = module_name__3elua_path, ["clear-cache!"] = clear_cache_21}
