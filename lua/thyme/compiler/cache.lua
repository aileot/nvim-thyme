local Path = require("thyme.util.path")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.util.pool")
local hide_files_in_dir_21 = _local_2_["hide-files-in-dir!"]
local _local_3_ = require("thyme.dependency.unit")
local clear_module_map_files_21 = _local_3_["clear-module-map-files!"]
local function determine_lua_path(module_name)
  local lua_module_path = (module_name:gsub("%.", Path.sep) .. ".lua")
  return Path.join(lua_cache_prefix, lua_module_path)
end
local function clear_cache_21()
  local case_4_
  local function _5_(_241)
    return (".lua" == _241:sub(-4))
  end
  case_4_ = vim.fs.find(_5_, {type = "file", path = lua_cache_prefix})
  if ((_G.type(case_4_) == "table") and (case_4_[1] == nil)) then
    return false
  else
    local _ = case_4_
    hide_files_in_dir_21(lua_cache_prefix)
    clear_module_map_files_21()
    return true
  end
end
return {["determine-lua-path"] = determine_lua_path, ["clear-cache!"] = clear_cache_21}
