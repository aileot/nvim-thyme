local Path = require("thyme.utils.path")
local _local_1_ = require("thyme.const")
local lua_cache_prefix = _local_1_["lua-cache-prefix"]
local _local_2_ = require("thyme.utils.pool")
local hide_files_in_dir_21 = _local_2_["hide-files-in-dir!"]
local Messenger = require("thyme.utils.messenger")
local CacheMessenger = Messenger.new("cache")
local _local_3_ = require("thyme.module-map.unit")
local clear_module_map_files_21 = _local_3_["clear-module-map-files!"]
local function determine_lua_path(module_name)
  local lua_module_path = (module_name:gsub("%.", Path.sep) .. ".lua")
  return Path.join(lua_cache_prefix, lua_module_path)
end
local function clear_cache_21()
  local _4_
  local function _5_(_241)
    return (".lua" == _241:sub(-4))
  end
  _4_ = vim.fs.find(_5_, {type = "file", path = lua_cache_prefix})
  if ((_G.type(_4_) == "table") and (_4_[1] == nil)) then
    local msg = ("no cache files detected at " .. lua_cache_prefix)
    CacheMessenger["notify!"](CacheMessenger, msg)
    return false
  else
    local _ = _4_
    local msg = ("clear all the cache under " .. lua_cache_prefix)
    hide_files_in_dir_21(lua_cache_prefix)
    clear_module_map_files_21()
    CacheMessenger["notify!"](CacheMessenger, msg)
    return true
  end
end
return {["determine-lua-path"] = determine_lua_path, ["clear-cache!"] = clear_cache_21}
