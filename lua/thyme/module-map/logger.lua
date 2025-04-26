local ModuleMap = require("thyme.module-map.unit")
local _local_1_ = require("thyme.utils.uri")
local uri_encode = _local_1_["uri-encode"]
local ModuleMapLogger = {}
ModuleMapLogger.__index = ModuleMapLogger
ModuleMapLogger.new = function()
  local self = setmetatable({}, ModuleMapLogger)
  return self
end
local module_maps
local function _2_(self, fnl_path)
  local modmap = ModuleMap.new(fnl_path)
  self[fnl_path] = modmap
  return modmap
end
module_maps = setmetatable({}, {__index = _2_})
local function log_module_map_21(dependency)
  local or_3_ = rawget(module_maps, dependency["fnl-path"])
  if not or_3_ then
    local modmap, logged_3f = ModuleMap.new(dependency["fnl-path"])
    if not logged_3f then
      modmap["initialize-module-map!"](modmap, dependency)
    else
    end
    module_maps[dependency["fnl-path"]] = modmap
    or_3_ = modmap
  end
  return or_3_
end
local function fnl_path__3eentry_map(fnl_path)
  local tgt_6_ = module_maps[fnl_path]
  return (tgt_6_)["get-entry-map"](tgt_6_)
end
local function fnl_path__3edependent_map(fnl_path)
  local tgt_7_ = module_maps[fnl_path]
  return (tgt_7_)["get-dependent-maps"](tgt_7_)[fnl_path]
end
local function fnl_path__3elua_path(fnl_path)
  local _8_ = fnl_path__3eentry_map(fnl_path)
  if (nil ~= _8_) then
    local modmap = _8_
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
return {["log-module-map!"] = log_module_map_21, ["fnl-path->entry-map"] = fnl_path__3eentry_map, ["fnl-path->dependent-map"] = fnl_path__3edependent_map, ["fnl-path->lua-path"] = fnl_path__3elua_path, ["clear-module-map!"] = clear_module_map_21, ["restore-module-map!"] = restore_module_map_21}
