local Path = require("thyme.utils.path")
local ModuleMap = require("thyme.module-map.unit")
local _local_1_ = require("thyme.utils.iterator")
local each_file = _local_1_["each-file"]
local _local_2_ = require("thyme.utils.pool")
local hide_file_21 = _local_2_["hide-file!"]
local _local_3_ = require("thyme.utils.uri")
local uri_encode = _local_3_["uri-encode"]
local _local_4_ = require("thyme.const")
local state_prefix = _local_4_["state-prefix"]
local modmap_prefix = Path.join(state_prefix, "modmap")
vim.fn.mkdir(modmap_prefix, "p")
local module_maps
local function _5_(self, fnl_path)
  local modmap = ModuleMap.new(fnl_path)
  do end (self)[fnl_path] = modmap
  return modmap
end
module_maps = setmetatable({}, {__index = _5_})
local function log_module_map_21(dependency, dependent_stack)
  local module_map
  local function _6_()
    local modmap, logged_3f = ModuleMap.new(dependency["fnl-path"])
    if not logged_3f then
      modmap["initialize-module-map!"](modmap, dependency)
    else
    end
    module_maps[dependency["fnl-path"]] = modmap
    return modmap
  end
  module_map = (rawget(module_maps, dependency["fnl-path"]) or _6_())
  local _8_ = dependent_stack[#dependent_stack]
  if (nil ~= _8_) then
    local dependent = _8_
    if not module_map["get-dependent-maps"](module_map)[dependent["fnl-path"]] then
      return module_map["add-dependent"](module_map, dependent)
    else
      return nil
    end
  else
    return nil
  end
end
local function fnl_path__3eentry_map(fnl_path)
  return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(module_maps[fnl_path], "get-entry-map")
end
local function fnl_path__3edependent_map(fnl_path)
  return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(module_maps[fnl_path], "get-dependent-maps")[fnl_path]
end
local function fnl_path__3elua_path(fnl_path)
  local _11_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _11_) then
    local modmap = _11_
    return modmap["lua-path"]
  else
    return nil
  end
end
local function clear_module_map_21(fnl_path)
  local modmap = module_maps[fnl_path]
  module_maps[uri_encode(fnl_path)] = modmap
  module_maps[fnl_path] = nil
  return nil
end
local function restore_module_map_21(fnl_path)
  local modmap = module_maps[uri_encode(fnl_path)]
  module_maps[fnl_path] = modmap
  return nil
end
local function clear_dependency_log_files_21()
  return each_file(hide_file_21, modmap_prefix)
end
return {["log-module-map!"] = log_module_map_21, ["fnl-path->entry-map"] = fnl_path__3eentry_map, ["fnl-path->dependent-map"] = fnl_path__3edependent_map, ["fnl-path->lua-path"] = fnl_path__3elua_path, ["clear-module-map!"] = clear_module_map_21, ["restore-module-map!"] = restore_module_map_21, ["clear-dependency-log-files!"] = clear_dependency_log_files_21}
